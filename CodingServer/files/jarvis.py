#!/usr/bin/env python3
import hmac
import json
import os
import random
import re
import threading
import time
import urllib.error
import urllib.request
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

API = f"{os.environ['AIONUI_URL']}/api"
STATE = os.environ['JARVIS_STATE']
TOKEN = os.environ.get('JARVIS_TOKEN', '')
MEDIA = os.environ['JARVIS_MEDIA_URL']
REQUEST = os.environ['JARVIS_REQUEST_URL']
VOICE = f"""You are Jarvis, a voice assistant reached through Siri.

- The user's words come from speech-to-text, so expect misheard words and no punctuation. Go with the most likely meaning, and ask a short question only when it is truly unclear.
- Reply in one to three short spoken sentences of plain text. Lead with the answer, say numbers, dates and times the way people speak, and never read out links, IDs, paths or code.
- Skip greetings, and never mention connectors, logins or setup issues.
- Act right away on things that are easy to undo, like lights, plugs, requesting a title or starting an app. Ask first before anything hard to undo, like deleting, pushing code or messaging someone.
- When asked to open, play or show something, end the reply with [open:URL] to open it in the user's browser. Use any web page, {MEDIA}/web/#/details?id=ITEM_ID for a Jellyfin title, or {REQUEST}/movie/TMDB_ID or {REQUEST}/tv/TMDB_ID for a title not in the library.
- When the user wants a new topic or a fresh conversation, reply only [jarvis:new].
- When the user wants to change the agent, model or thinking level, reply only [jarvis:use agent=AGENT model=MODEL thinking=LEVEL] in their words, leaving out parts they did not mention. AGENT is claude, antigravity, codex or opencode, and "agy" means antigravity."""
AGENTS = {'claude': 'Claude Code', 'antigravity': 'Antigravity', 'codex': 'Codex', 'opencode': 'OpenCode'}
AGENT_WORDS = {'claude': {'claude', 'anthropic'}, 'antigravity': {'agy', 'antigravity'}, 'codex': {'codex', 'openai'}, 'opencode': {'opencode', 'open'}}
FILLER = {'code', 'model', 'version', 'latest', 'newest', 'thinking', 'reasoning', 'effort', 'level', 'with', 'the', 'and', 'use', 'to', 'on'}
LEVELS = ['low', 'medium', 'high', 'xhigh', 'max', 'ultracode']
LEVEL_WORDS = {'minimal': 'low', 'low': 'low', 'med': 'medium', 'medium': 'medium', 'normal': 'medium', 'high': 'high',
               'xhigh': 'xhigh', 'extra': 'xhigh', 'very': 'xhigh', 'max': 'max', 'maximum': 'max', 'highest': 'max', 'ultra': 'ultracode', 'ultracode': 'ultracode'}
ASKS = ["what's up?", 'what do you need?', "what's on your mind?", 'how can I help?', 'what can I do for you?']
GOODBYE = re.compile(r"^\W*(done|stop|thanks|thank you|that'?s all|bye|goodbye)\W*$", re.I)
OPEN = re.compile(r'\[open:\s*(https?://[^\]\s]+)\s*\]', re.I)
USE = re.compile(r'\[jarvis:use([^\]]*)\]', re.I)
FIELD = re.compile(r'(agent|model|thinking)=(.*?)(?=\s+(?:agent|model|thinking)=|$)', re.I)
TURN_TIMEOUT = 20
POLL = 0.1
FULL = 0.9

lock = threading.Lock()
pending = None


def load():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {'agent': 'claude'}


state = load()


def save():
    with open(STATE, 'w') as f:
        json.dump(state, f)


def api(path, body=None, method=None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(f'{API}{path}', data=data, headers={'content-type': 'application/json'}, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as res:
            return res.status, json.loads(res.read() or b'{}').get('data')
    except urllib.error.HTTPError as err:
        return err.code, None


def tokens(text):
    return re.findall(r'[a-z]+|\d+(?:\.\d+)?', (text or '').lower())


def level(text):
    words = {LEVEL_WORDS[w] for w in tokens(text) if w in LEVEL_WORDS}
    return next((name for name in reversed(LEVELS) if name in words), None)


def nearest(wanted, available):
    rank = lambda name: abs(LEVELS.index(name) - LEVELS.index(wanted))
    return min((a for a in available if a in LEVELS), key=rank, default=None) if wanted else None


def assistant(agent):
    kind = lambda a: (a.get('agent') or {}).get('acp_backend') or (a.get('agent') or {}).get('type')
    match = next((a for a in api('/assistants')[1] or [] if a.get('source') == 'generated' and kind(a) == agent), None)
    if not match:
        raise RuntimeError(f'{AGENTS[agent]} is not available')
    return match['id']


def catalog(agent):
    row_id = assistant(agent).split(':')[-1]
    row = next((r for r in api('/agents/management')[1] or [] if r.get('id') == row_id), {})
    return [m for m in (row.get('available_models') or {}).get('available_models') or [] if m['id'] != 'default']


def version(model):
    found = re.search(r'\d+(?:\.\d+)*', model.get('label') or model['id'])
    return tuple(int(part) for part in found[0].split('.')) if found else ()


def resolve(agent, wanted, effort):
    words = [w for w in tokens(wanted) if w not in AGENT_WORDS[agent] | FILLER and w not in LEVEL_WORDS]
    models = catalog(agent)
    has = lambda m, needed: all(w in tokens(m.get('label') if w[0].isdigit() else f"{m['id']} {m.get('label', '')}") for w in needed)
    found = [m for m in models if has(m, words)] or [m for m in models if has(m, [w for w in words if not w[0].isdigit()])]
    if not words or not found:
        raise RuntimeError(f"I couldn't find {wanted} for {AGENTS[agent]}")
    newest = max(map(version, found))
    found = [m for m in found if version(m) == newest]
    variants = {m['id'].rsplit('-', 1)[-1]: m for m in found if m['id'].rsplit('-', 1)[-1] in LEVELS}
    pick = nearest(effort or 'high', variants)
    return variants[pick] if pick else found[0]


def conversation():
    if state.get('conversation') and api(f"/conversations/{state['conversation']}")[0] == 200:
        return state['conversation']
    overrides = {k: v for k, v in {'model': state.get('model'), 'thought_level': state.get('effort')}.items() if v}
    body = {'assistant': {'id': assistant(state['agent']), 'conversation_overrides': overrides}, 'name': 'Jarvis', 'extra': {'session_mode': 'yolo', 'preset_context': VOICE}}
    state['conversation'] = api('/conversations', body)[1]['id']
    save()
    return state['conversation']


def configure(cid, option, value):
    status, data = api(f'/conversations/{cid}/config-options/{option}', {'value': value}, 'PUT')
    if status != 200 or (data or {}).get('confirmation') == 'command_ack':
        raise RuntimeError(f'AionUi rejected the {option} change ({status})')


def use(fields):
    agent = next((name for name, words in AGENT_WORDS.items() if set(tokens(fields.get('agent'))) & words), state['agent'])
    effort = level(fields.get('thinking'))
    wanted = fields.get('model') or (state.get('model') if agent == state['agent'] and agent == 'antigravity' and effort else None)
    model = resolve(agent, wanted, effort) if wanted else None
    current = model or next((m for m in catalog(agent) if m['id'] == state.get('model')), None)
    effort = nearest(effort, (current.get('reasoning_efforts') or []) if current else LEVELS)
    if agent != state['agent'] or agent == 'antigravity':
        state.update(agent=agent, model=model and model['id'], effort=effort, conversation=None)
    else:
        cid = conversation()
        api(f'/conversations/{cid}/runtime/ensure', {})
        if model:
            configure(cid, 'model', model['id'])
            state['model'] = model['id']
        if effort:
            configure(cid, 'effort', effort)
            state['effort'] = effort
    save()
    detail = ', '.join(filter(None, [model and model.get('label'), effort and f'{effort} thinking']))
    return f"Using {AGENTS[agent]}{f' with {detail}' if detail else ''}."


def busy(cid):
    return bool(((api(f'/conversations/{cid}')[1] or {}).get('runtime') or {}).get('is_processing'))


def latest(cid):
    return api(f'/conversations/{cid}/messages/latest?type=text')[1] or {}


def send(cid, text):
    for _ in range(300):
        if not busy(cid):
            status, data = api(f'/conversations/{cid}/messages', {'content': text})
            if data and data.get('turn_id'):
                return
            if status != 409:
                raise RuntimeError(f'AionUi refused the message ({status})')
        time.sleep(POLL)
    raise RuntimeError('the agent is still busy')


def reply(cid, previous):
    started, idle, deadline = False, 0, time.monotonic() + TURN_TIMEOUT
    while time.monotonic() < deadline:
        if busy(cid):
            started, idle = True, 0
        else:
            message = latest(cid)
            if message.get('id') != previous and message.get('position') == 'left':
                return (message.get('content') or {}).get('content', '')
            idle += 1
            if started and idle > 20:
                raise RuntimeError('the agent stopped without answering')
        time.sleep(POLL)
    return None


def full(cid):
    usage = api(f'/conversations/{cid}/usage')[1] or {}
    return bool(usage.get('size')) and usage.get('used', 0) / usage['size'] >= FULL


def title(cid, first):
    for _ in range(15):
        data = api(f'/conversations/{cid}')[1] or {}
        if data.get('name_source') == 'agent':
            break
        time.sleep(2)
    topic = data.get('name') if data.get('name_source') == 'agent' else ' '.join(first.split()[:6])
    api(f'/conversations/{cid}', {'name': f'Jarvis | {topic}', 'name_source': 'user'}, 'PATCH')


def speakable(text):
    text = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', text)
    text = re.sub(r'^\s*[-•*]\s+', '', text, flags=re.M)
    text = re.sub(r'[*_`#>|]', '', text)
    return re.sub(r'\s+', ' ', text).strip() or 'Done.'


def greeting(name):
    hour = datetime.now().hour
    part = 'Hey' if hour < 5 else 'Morning' if hour < 12 else 'Afternoon' if hour < 17 else 'Evening'
    return f"{part}{f' {name}' if name else ''}, {random.choice(ASKS)}"


def ask(text, wait=False):
    global pending
    if not wait and GOODBYE.match(text):
        return {'say': 'Goodbye.'}
    if wait or (pending and busy(pending[0])):
        if not pending:
            return {'say': 'I lost track of that one. Ask me again.'}
        cid, previous = pending
    else:
        cid = conversation()
        previous = latest(cid).get('id')
        send(cid, text)
        if state.get('titled') != cid:
            state['titled'] = cid
            save()
            threading.Thread(target=title, args=(cid, text), daemon=True).start()
    answer = reply(cid, previous)
    if answer is None:
        pending = (cid, previous)
        return {'say': 'Still working on it.', 'pending': True}
    pending = None
    if '[jarvis:new]' in answer.lower():
        state['conversation'] = None
        save()
        return {'say': 'Okay, starting fresh.'}
    if command := USE.search(answer):
        return {'say': use({k.lower(): v.strip() for k, v in FIELD.findall(command[1].strip())})}
    result = {'say': speakable(re.sub(r'\[open:[^\]]*\]', '', answer, flags=re.I))}
    if found := OPEN.search(answer):
        result['open'] = found[1]
    if full(cid):
        state['conversation'] = None
        save()
        result['say'] += " This chat is full, so I'll start a fresh one next."
    return result


def warm():
    with lock:
        try:
            api(f'/conversations/{conversation()}/runtime/ensure', {})
        except Exception:
            pass


class Handler(BaseHTTPRequestHandler):
    def respond(self, status, body=b'', kind='text/plain; charset=utf-8'):
        self.send_response(status)
        self.send_header('content-type', kind)
        self.send_header('content-length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path != '/health':
            return self.respond(404)
        try:
            healthy = api('/assistants')[0] == 200
        except OSError:
            healthy = False
        self.respond(200 if healthy else 503)

    def do_POST(self):
        if not TOKEN or not hmac.compare_digest(self.headers.get('authorization', '').encode(), f'Bearer {TOKEN}'.encode()):
            return self.respond(401, b'Unauthorized')
        try:
            body = json.loads(self.rfile.read(int(self.headers.get('content-length') or 0)) or b'{}')
        except ValueError:
            body = {}
        if not isinstance(body, dict):
            body = {}
        if self.path == '/wake':
            threading.Thread(target=warm, daemon=True).start()
            return self.respond(200, greeting(str(body.get('name', '')).strip()).encode())
        if self.path != '/ask':
            return self.respond(404)
        text, wait = str(body.get('text', '')).strip(), bool(body.get('wait'))
        result = {'say': "I didn't catch that."}
        if text or wait:
            with lock:
                try:
                    result = ask(text, wait)
                except Exception as err:
                    result = {'say': f'Sorry, {err}.'}
        self.respond(200, json.dumps(result).encode(), 'application/json')


if __name__ == '__main__':
    ThreadingHTTPServer.daemon_threads = True
    ThreadingHTTPServer(('127.0.0.1', int(os.environ['JARVIS_PORT'])), Handler).serve_forever()
