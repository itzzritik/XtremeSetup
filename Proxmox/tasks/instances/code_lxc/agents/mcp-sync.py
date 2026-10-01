#!/usr/bin/env python3
# Makes every agent's MCP servers exactly match agents/mcp/*/mcp.json. Never prints secret values.
import fcntl
import glob
import json
import os
import re
import subprocess
import sys

# paths are filled in by Ansible (code_lxc.yml lxc_paths, agents.yml mcp_sync)
SOURCE = '{{ mcp_sync.source }}'
CLAUDE = '{{ lxc_paths.claude_json }}'
CODEX = '{{ lxc_paths.codex }}/config.toml'
OPENCODE = '{{ lxc_paths.opencode }}/opencode.jsonc'
GEMINI = '{{ lxc_paths.gemini_config }}/mcp_config.json'
BEGIN = '# BEGIN MCP-SYNC (generated from agents/mcp, edit there)'
END = '# END MCP-SYNC'

changed, failed = [], []


def read(path, default=''):
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        return default


def write(path, text):
    # resolve first so linked files are written in place instead of replacing the link
    path = os.path.realpath(path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = f'{path}.mcp-sync'
    with open(tmp, 'w') as f:
        f.write(text)
    os.chmod(tmp, 0o600)
    os.replace(tmp, path)


def load_servers():
    servers = {}
    # mcp/{name}/mcp.json, plus the older flat mcp/{name}.json; the folder wins if both exist
    found = [(os.path.basename(os.path.dirname(p)), p) for p in sorted(glob.glob(f'{SOURCE}/*/mcp.json'))]
    found += [(os.path.basename(p)[:-5], p) for p in sorted(glob.glob(f'{SOURCE}/*.json'))]
    for name, path in found:
        if name in servers:
            continue
        try:
            spec = json.loads(read(path))
            required = 'url' if spec['type'] == 'http' else 'command'
            if spec['type'] not in ('http', 'stdio') or not spec.get(required):
                raise ValueError
        except Exception:
            failed.append(f'{name}: invalid file')
            continue
        servers[name] = spec
    return servers


def entry(agent, spec):
    http = spec['type'] == 'http'
    if agent == 'gemini':
        item = {'serverUrl': spec['url'], 'headers': spec.get('headers')} if http else {
            'command': spec['command'], 'args': spec.get('args'), 'env': spec.get('env')}
    elif agent == 'opencode':
        item = {'type': 'remote', 'url': spec['url'], 'headers': spec.get('headers'), 'oauth': False} if http else {
            'type': 'local', 'command': [spec['command'], *spec.get('args', [])], 'environment': spec.get('env')}
    else:
        item = dict(spec)
    return {k: v for k, v in item.items() if v is not None}


def sync_claude(servers):
    current = json.loads(read(CLAUDE, '{}')).get('mcpServers', {})

    def claude(*args):
        subprocess.run(['claude', 'mcp', *args, '-s', 'user'], check=True, capture_output=True, text=True)

    for name in current.keys() - servers.keys():
        claude('remove', name)
        changed.append(f'claude -{name}')
    for name, spec in servers.items():
        if current.get(name) == entry('claude', spec):
            continue
        if name in current:
            claude('remove', name)
        claude('add-json', name, json.dumps(spec))
        changed.append(f'claude {name}')


def toml_value(value):
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, list):
        return '[' + ', '.join(map(toml_value, value)) + ']'
    if isinstance(value, dict):
        return '{ ' + ', '.join(f'{json.dumps(k)} = {toml_value(v)}' for k, v in value.items()) + ' }'
    return json.dumps(value)


def codex_table(name, spec):
    key = name if re.fullmatch(r'[A-Za-z0-9_-]+', name) else json.dumps(name)
    if spec['type'] == 'http':
        fields = {'url': spec['url'], 'http_headers': spec.get('headers')}
    else:
        fields = {'command': spec['command'], 'args': spec.get('args'), 'env': spec.get('env')}
    return '\n'.join([f'[mcp_servers.{key}]'] + [f'{k} = {toml_value(v)}' for k, v in fields.items() if v])


def drop_mcp_tables(text):
    kept, skip = [], False
    for line in text.splitlines():
        header = re.match(r'\s*\[+\s*([^\]]+?)\s*\]+\s*$', line)
        if header:
            skip = header.group(1).startswith('mcp_servers.')
        if not skip:
            kept.append(line)
    return '\n'.join(kept)


def sync_codex(servers):
    original = read(CODEX)
    text = re.sub(rf'{re.escape(BEGIN)}.*?{re.escape(END)}\n?', '', original, flags=re.S)
    text = drop_mcp_tables(text).rstrip()
    new = text + '\n' if text else ''
    if servers:
        tables = '\n\n'.join(codex_table(n, s) for n, s in servers.items())
        new = (new + '\n' if new else '') + f'{BEGIN}\n{tables}\n{END}\n'
    if new != original:
        write(CODEX, new)
        changed.append('codex')


def sync_json(agent, path, key, servers):
    raw = read(path, '{}')
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        data = json.loads(re.sub(r',(\s*[}\]])', r'\1', re.sub(r'^\s*//.*$', '', raw, flags=re.M)))
    want = {name: entry(agent, spec) for name, spec in servers.items()}
    if data.get(key, {}) != want:
        data[key] = want
        write(path, json.dumps(data, indent=2) + '\n')
        changed.append(agent)


def main():
    # lock this script's own file so two syncs never run at once
    lock = open(__file__)
    fcntl.flock(lock, fcntl.LOCK_EX)
    servers = load_servers()
    if failed:
        # a half-edited file must not remove its server from every agent
        for item in failed:
            print(f'FAILED {item}, nothing synced', file=sys.stderr)
        sys.exit(1)
    agents = {
        'claude': lambda: sync_claude(servers),
        'codex': lambda: sync_codex(servers),
        'opencode': lambda: sync_json('opencode', OPENCODE, 'mcp', servers),
        'gemini': lambda: sync_json('gemini', GEMINI, 'mcpServers', servers),
    }
    for agent, sync in agents.items():
        try:
            sync()
        except Exception as error:
            failed.append(f'{agent}: {type(error).__name__}')
    for item in changed:
        print(f'CHANGED {item}')
    for item in failed:
        print(f'FAILED {item}', file=sys.stderr)
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
