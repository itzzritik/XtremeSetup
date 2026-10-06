#!/usr/bin/env python3
import base64
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import yaml

SPEC = json.loads(os.environ.get('MEDIA_SYNC') or open(sys.argv[1]).read())
USER = os.environ.get('MEDIA_USER', '')
PASSWORD = os.environ.get('MEDIA_PASSWORD', '')
ARR_KEY = os.environ.get('MEDIA_ARR_KEY', '')
JELLYFIN_KEY_INSERT = '''
import datetime, sqlite3, sys
now = datetime.datetime.now(datetime.UTC).strftime('%Y-%m-%d %H:%M:%S.%f')
db = sqlite3.connect('/var/lib/jellyfin/data/jellyfin.db')
db.execute('insert into ApiKeys (DateCreated, DateLastActivity, Name, AccessToken) values (?, ?, ?, ?)', (now, '0001-01-01 00:00:00', 'Jarvis', sys.stdin.read().strip()))
db.commit()
'''
HOST = SPEC['host']
CONFIGS = SPEC['configs']


def log(msg):
    print(msg, flush=True)


def request(url, method='GET', data=None, headers=None, form=False):
    headers = dict(headers or {})
    body = None
    if data is not None:
        if form:
            body = urllib.parse.urlencode(data, doseq=True).encode()
            headers['Content-Type'] = 'application/x-www-form-urlencoded'
        else:
            body = json.dumps(data).encode()
            headers['Content-Type'] = 'application/json'
    req = urllib.request.Request(url, data=body, method=method, headers=headers)
    with urllib.request.urlopen(req, timeout=120) as resp:
        text = resp.read().decode()
    return json.loads(text) if text[:1] and text[0] in '[{' else text


def arr_key(app):
    return re.search(r'<ApiKey>([^<]+)</ApiKey>', open(f'{CONFIGS}/{app}/config.xml').read()).group(1)


def arr(kind):
    return next(a for a in SPEC['arrs'] if a['kind'] == kind)


def set_fields(fields, values):
    for field in fields:
        if field['name'] in values:
            field['value'] = values[field['name']]


def fields_match(fields, values):
    current = {f['name']: f.get('value') for f in fields}
    return all(current.get(k) == v or str(current.get(k)).strip('*') == '' for k, v in values.items())


def differs(current, wanted):
    return sorted(k for k, v in wanted.items() if current.get(k) != v)


def upsert(base, items, match, payload, headers, label):
    item = next((i for i in items if match(i)), None)
    if item is not None and not differs(item, payload):
        return False
    if item is None:
        request(base, 'POST', payload, headers)
    else:
        request(f"{base}/{item['id']}", 'PUT', {k: v for k, v in dict(item, **payload).items() if k != 'id'}, headers)
    log(f'CHANGED {label}')
    return True


def sync_provider(base, headers, resource, implementation, name, values, flags, secrets=None):
    item = next((i for i in request(f'{base}/{resource}', headers=headers) if i['name'] == name), None)
    if item is not None and fields_match(item['fields'], values) and not differs(item, flags):
        return False
    if item is None:
        item = next(s for s in request(f'{base}/{resource}/schema', headers=headers) if s['implementation'] == implementation)
        item['name'] = name
    set_fields(item['fields'], dict(values, **(secrets or {})))
    item.update(flags)
    path = f"{base}/{resource}/{item['id']}" if 'id' in item else f'{base}/{resource}'
    request(f'{path}?forceSave=true', 'PUT' if 'id' in item else 'POST', item, headers)
    return True


def qbit_password_set():
    conf = open(f'{CONFIGS}/qbittorrent/qBittorrent.conf').read()
    match = re.search(r'Password_PBKDF2="?@ByteArray\(([^:]+):([^)]+)\)', conf)
    if not match:
        return False
    salt, digest = (base64.b64decode(part) for part in match.groups())
    return hashlib.pbkdf2_hmac('sha512', PASSWORD.encode(), salt, 100000) == digest


def sync_qbittorrent(cfg):
    base = f"http://{HOST}:{cfg['port']}/api/v2"
    diff = {k: v for k, v in cfg['prefs'].items() if request(f'{base}/app/preferences').get(k) != v}
    if not qbit_password_set():
        diff['web_ui_password'] = PASSWORD
    if diff:
        request(f'{base}/app/setPreferences', 'POST', {'json': json.dumps(diff)}, form=True)
        log('CHANGED qbittorrent prefs: ' + ', '.join(sorted(k.replace('web_ui_password', 'password') for k in diff)))
    categories = request(f'{base}/torrents/categories')
    for name, path in cfg['categories'].items():
        if name not in categories:
            request(f'{base}/torrents/createCategory', 'POST', {'category': name, 'savePath': path}, form=True)
        elif categories[name].get('savePath') != path:
            request(f'{base}/torrents/editCategory', 'POST', {'category': name, 'savePath': path}, form=True)
        else:
            continue
        log(f'CHANGED qbittorrent category {name}')


def sync_arrs(cfg):
    qbit = SPEC['qbittorrent']
    for app in cfg:
        base = f"http://{HOST}:{app['port']}/api/v3"
        headers = {'X-Api-Key': arr_key(app['name'])}
        name = app['name']

        existing = [r['path'] for r in request(f'{base}/rootfolder', headers=headers)]
        for root in app['roots']:
            if root not in existing:
                request(f'{base}/rootfolder', 'POST', {'path': root}, headers)
                log(f'CHANGED {name} root folder {root}')

        category = 'movieCategory' if app['kind'] == 'radarr' else 'tvCategory'
        values = {'host': HOST, 'port': int(qbit['port']), 'username': USER, category: app['category']}
        flags = {'enable': True, 'removeCompletedDownloads': True, 'removeFailedDownloads': True, 'priority': 1}
        if sync_provider(base, headers, 'downloadclient', 'QBittorrent', 'qBittorrent', values, flags, {'password': PASSWORD}):
            log(f'CHANGED {name} download client')

        script = {'path': f"/usr/local/sma/post{name.title()}.sh"}
        if sync_provider(base, headers, 'notification', 'CustomScript', 'SMA', script, {'onDownload': True, 'onUpgrade': True}):
            log(f'CHANGED {name} SMA script')

        mm = request(f'{base}/config/mediamanagement', headers=headers)
        diff = differs(mm, app['media_management'])
        if diff:
            request(f"{base}/config/mediamanagement/{mm['id']}", 'PUT', dict(mm, **app['media_management']), headers)
            log(f"CHANGED {name} media management: {', '.join(diff)}")


def sync_prowlarr(cfg):
    base = f"http://{HOST}:{cfg['port']}/api/v1"
    headers = {'X-Api-Key': arr_key('prowlarr')}
    changed = False

    tag = next((t for t in request(f'{base}/tag', headers=headers) if t['label'] == 'flaresolverr'), None) \
        or request(f'{base}/tag', 'POST', {'label': 'flaresolverr'}, headers)

    values = {'host': cfg['flaresolverr'], 'requestTimeout': 60}
    proxy = next((p for p in request(f'{base}/indexerProxy', headers=headers) if p['implementation'] == 'FlareSolverr'), None)
    if proxy is None or not fields_match(proxy['fields'], values) or proxy.get('tags') != [tag['id']]:
        proxy = proxy or dict(next(s for s in request(f'{base}/indexerProxy/schema', headers=headers) if s['implementation'] == 'FlareSolverr'), name='FlareSolverr')
        set_fields(proxy['fields'], values)
        proxy['tags'] = [tag['id']]
        request(f"{base}/indexerProxy/{proxy['id']}" if 'id' in proxy else f'{base}/indexerProxy', 'PUT' if 'id' in proxy else 'POST', proxy, headers)
        log('CHANGED prowlarr FlareSolverr proxy')

    current = {i['definitionName']: i for i in request(f'{base}/indexer', headers=headers)}
    schema = None
    for wanted in cfg['indexers']:
        tags = [tag['id']] if wanted.get('flaresolverr') else []
        url = {'baseUrl': wanted['url']} if 'url' in wanted else {}
        indexer = current.get(wanted['definition'])
        if indexer is not None and sorted(indexer.get('tags', [])) == tags and fields_match(indexer['fields'], url):
            continue
        if indexer is None:
            schema = schema or request(f'{base}/indexer/schema', headers=headers)
            indexer = next((s for s in schema if s.get('definitionName') == wanted['definition']), None)
            if indexer is None:
                log(f"SKIP prowlarr indexer {wanted['definition']}: no such definition")
                continue
            indexer.update({'enable': True, 'appProfileId': 1, 'priority': 25})
        indexer['tags'] = tags
        set_fields(indexer['fields'], url)
        try:
            request(f"{base}/indexer/{indexer['id']}" if 'id' in indexer else f'{base}/indexer', 'PUT' if 'id' in indexer else 'POST', indexer, headers)
            log(f"CHANGED prowlarr indexer {indexer['name']}")
            changed = True
        except urllib.error.HTTPError as err:
            log(f"SKIP prowlarr indexer {wanted['definition']}: {err.read().decode()[:200]}".replace('\n', ' '))

    apps = request(f'{base}/applications', headers=headers)
    for app in SPEC['arrs']:
        values = {'prowlarrUrl': f"http://{HOST}:{cfg['port']}", 'baseUrl': f"http://{HOST}:{app['port']}",
                  'apiKey': arr_key(app['name']), 'syncCategories': app['sync_categories']}
        current_app = next((a for a in apps if a['name'] == app['prowlarr_name']), None)
        if current_app is not None and current_app.get('syncLevel') == 'fullSync' and fields_match(current_app['fields'], values):
            try:
                request(f'{base}/applications/test', 'POST', current_app, headers)
                continue
            except urllib.error.HTTPError:
                pass
        if current_app is None:
            impl = app['kind'].capitalize()
            current_app = dict(next(s for s in request(f'{base}/applications/schema', headers=headers) if s['implementation'] == impl), name=app['prowlarr_name'])
        set_fields(current_app['fields'], values)
        current_app['syncLevel'] = 'fullSync'
        request(f"{base}/applications/{current_app['id']}" if 'id' in current_app else f'{base}/applications', 'PUT' if 'id' in current_app else 'POST', current_app, headers)
        log(f"CHANGED prowlarr app {app['prowlarr_name']}")
        changed = True

    if changed:
        request(f'{base}/command', 'POST', {'name': 'ApplicationIndexerSync', 'forceSync': True}, headers)


def sync_bazarr(cfg):
    conf = yaml.safe_load(open(f'{CONFIGS}/bazarr/config/config.yaml'))
    headers = {'X-API-KEY': conf['auth']['apikey']}
    base = f"http://{HOST}:{cfg['port']}/api"

    wanted = dict(cfg['settings'])
    for kind in ('sonarr', 'radarr'):
        app = arr(kind)
        wanted.update({f'general-use_{kind}': True, f'{kind}-ip': HOST, f'{kind}-port': app['port'],
                       f'{kind}-apikey': arr_key(app['name']), f'{kind}-base_url': '/'})

    form, drift = [], []
    for name, value in wanted.items():
        section, option = name.split('-', 1)
        have = (conf.get(section) or {}).get(option)
        if isinstance(value, list):
            same = sorted(have or []) == sorted(value)
            form += [(f'settings-{name}', v) for v in value]
        elif isinstance(value, bool):
            same = have is value
            form.append((f'settings-{name}', str(value).lower()))
        else:
            same = str(have) == str(value)
            form.append((f'settings-{name}', str(value)))
        if not same:
            drift.append(name)

    def comparable(profile):
        return profile['name'], [(i['language'], str(i['hi']), str(i['forced'])) for i in profile['items']]
    if [comparable(p) for p in request(f'{base}/system/languages/profiles', headers=headers)] != [comparable(p) for p in cfg['language_profiles']]:
        drift.append('language profiles')
        form.append(('languages-profiles', json.dumps(cfg['language_profiles'])))
        form += [('languages-enabled', lang) for lang in cfg['languages']]

    if drift:
        request(f'{base}/system/settings', 'POST', form, headers, form=True)
        log('CHANGED bazarr: ' + ', '.join(sorted(d for d in drift if 'apikey' not in d) or ['apikeys']))


def write_owned(path, text, mode):
    if os.path.exists(path) and open(path).read() == text:
        return False
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(text)
    os.chown(path, int(SPEC['uid']), int(SPEC['uid']))
    os.chmod(path, mode)
    return True


def language_format(fmt, languages):
    if 'except' in fmt:
        matches = [(name, lid, False) for name, lid in languages.items() if lid > 0 and name not in fmt['except']]
    else:
        matches = [(fmt['language'], languages[fmt['language']], fmt.get('negate', False))]
    return {'trash_id': hashlib.md5(fmt['name'].encode()).hexdigest(), 'name': fmt['name'], 'includeCustomFormatWhenRenaming': False,
            'specifications': [{'name': name, 'implementation': 'LanguageSpecification', 'negate': negate, 'required': False,
                                'fields': {'value': lid, 'exceptLanguage': False}} for name, lid, negate in matches]}


def pct(lxc, *args, stdin=None):
    subprocess.run(['pct', 'exec', str(lxc), '--keep-env', '0', '--', *args], input=stdin, text=True, capture_output=True, check=True)


def wait_up(url):
    for _ in range(90):
        try:
            return request(url)
        except Exception:
            time.sleep(2)
    raise RuntimeError(f'{url} did not come back')


def sync_keys(cfg):
    ports = {'radarr': arr('radarr')['port'], 'sonarr': arr('sonarr')['port'], 'prowlarr': SPEC['prowlarr']['port']}
    for name, port in ports.items():
        path = f'{CONFIGS}/{name}/config.xml'
        if arr_key(name) != ARR_KEY:
            text = re.sub(r'<ApiKey>[^<]*</ApiKey>', f'<ApiKey>{ARR_KEY}</ApiKey>', open(path).read())
            with open(path, 'w') as f:
                f.write(text)
            pct(cfg['lxc'], 'docker', 'restart', name)
            wait_up(f'http://{HOST}:{port}/ping')
            log(f'CHANGED {name} api key')

    path = f'{CONFIGS}/jellyseerr/settings.json'
    if json.load(open(path))['main']['apiKey'] != ARR_KEY:
        pct(cfg['lxc'], 'docker', 'stop', 'jellyseerr')
        settings = json.load(open(path))
        settings['main']['apiKey'] = ARR_KEY
        with open(path, 'w') as f:
            json.dump(settings, f, indent=1)
        pct(cfg['lxc'], 'docker', 'start', 'jellyseerr')
        wait_up(f"http://{HOST}:{SPEC['jellyseerr']['port']}/api/v1/status")
        log('CHANGED seerr api key')

    current = yaml.safe_load(open(f'{CONFIGS}/bazarr/config/config.yaml'))['auth']['apikey']
    if current != ARR_KEY:
        request(f"http://{HOST}:{SPEC['bazarr']['port']}/api/system/settings", 'POST', [('settings-auth-apikey', ARR_KEY)], {'X-API-KEY': current}, form=True)
        log('CHANGED bazarr api key')

    jellyfin = SPEC['jellyfin']['url']
    try:
        request(f'{jellyfin}/System/Info', headers={'Authorization': f'MediaBrowser Token="{ARR_KEY}"'})
    except urllib.error.HTTPError as err:
        if err.code != 401:
            raise
        pct(cfg['jellyfin_lxc'], 'systemctl', 'stop', 'jellyfin')
        pct(cfg['jellyfin_lxc'], 'python3', '-c', JELLYFIN_KEY_INSERT, stdin=ARR_KEY)
        pct(cfg['jellyfin_lxc'], 'systemctl', 'start', 'jellyfin')
        wait_up(f'{jellyfin}/System/Info/Public')
        log('CHANGED jellyfin api key')


def sync_recyclarr(cfg):
    text = ''.join(f"{a['name']}_apikey: {arr_key(a['name'])}\n" for a in SPEC['arrs'])
    if write_owned(f'{CONFIGS}/recyclarr/secrets.yml', text, 0o600):
        log('CHANGED recyclarr secrets')
    radarr = arr('radarr')
    languages = {l['name']: l['id'] for l in request(f"http://{HOST}:{radarr['port']}/api/v3/language", headers={'X-Api-Key': arr_key('radarr')})}
    for fmt in cfg['language_formats']:
        data = language_format(fmt, languages)
        if write_owned(f"{CONFIGS}/recyclarr/language-formats/{data['trash_id']}.json", json.dumps(data, indent=2) + '\n', 0o644):
            log(f"CHANGED recyclarr language format {fmt['name']}")
    out = subprocess.run(['pct', 'exec', str(cfg['lxc']), '--keep-env', '0', '--', 'docker', 'exec', 'recyclarr', 'recyclarr', 'sync'],
                         capture_output=True, text=True, check=True).stdout
    if re.search('Created|Updated|Deleted|has been updated', out):
        log('CHANGED recyclarr: ' + '; '.join(l.split('] ', 1)[-1] for l in out.splitlines() if re.search('Created|Updated|Deleted|has been updated', l)))


def sync_profiles(cfg):
    base = f"http://{HOST}:{cfg['port']}/api/v3"
    headers = {'X-Api-Key': arr_key('radarr')}
    profiles = {p['name']: p['id'] for p in request(f'{base}/qualityprofile', headers=headers)}
    wanted = {language: rule['profile'] for rule in cfg['rules'] for language in rule['languages']}
    moves = {}
    for movie in request(f'{base}/movie', headers=headers):
        profile = wanted.get((movie.get('originalLanguage') or {}).get('name'), cfg['default'])
        audio = ((movie.get('movieFile') or {}).get('mediaInfo') or {}).get('audioLanguages', '')
        if profile == cfg['keep_hindi']['from'] and 'hin' in audio.split('/'):
            profile = cfg['keep_hindi']['to']
        if movie['qualityProfileId'] != profiles[profile]:
            moves.setdefault(profile, []).append(movie['id'])
    for profile, movie_ids in moves.items():
        request(f'{base}/movie/editor', 'PUT', {'movieIds': movie_ids, 'qualityProfileId': profiles[profile]}, headers)
        log(f'CHANGED radarr profile {profile}: {len(movie_ids)} movies')


def sync_jellyfin(cfg):
    base = cfg['url']
    client = 'MediaBrowser Client="media-sync", Device="ansible", DeviceId="media-sync", Version="1.0"'
    token = request(f'{base}/Users/AuthenticateByName', 'POST', {'Username': USER, 'Pw': PASSWORD}, {'Authorization': client})['AccessToken']
    headers = {'Authorization': f'{client}, Token="{token}"'}

    encoding = request(f'{base}/System/Configuration/encoding', headers=headers)
    diff = differs(encoding, cfg['encoding'])
    if diff:
        request(f'{base}/System/Configuration/encoding', 'POST', dict(encoding, **cfg['encoding']), headers)
        log(f"CHANGED jellyfin encoding: {', '.join(diff)}")

    folders = {f['Name']: f for f in request(f'{base}/Library/VirtualFolders', headers=headers)}
    refresh = False
    for lib in cfg['libraries']:
        folder = folders.get(lib['name'])
        if folder is None:
            query = urllib.parse.urlencode({'name': lib['name'], 'collectionType': lib['type'], 'paths': lib['path'], 'refreshLibrary': 'false'})
            request(f'{base}/Library/VirtualFolders?{query}', 'POST', {'LibraryOptions': lib['options']}, headers)
            log(f"CHANGED jellyfin library {lib['name']} created")
            refresh = True
            continue
        if folder['Locations'] != [lib['path']]:
            if lib['path'] not in folder['Locations']:
                request(f'{base}/Library/VirtualFolders/Paths?refreshLibrary=false', 'POST', {'Name': lib['name'], 'PathInfo': {'Path': lib['path']}}, headers)
            for old in folder['Locations']:
                if old != lib['path']:
                    request(f"{base}/Library/VirtualFolders/Paths?{urllib.parse.urlencode({'name': lib['name'], 'path': old, 'refreshLibrary': 'false'})}", 'DELETE', headers=headers)
            log(f"CHANGED jellyfin library {lib['name']} path")
            refresh = True
        diff = differs(folder['LibraryOptions'], lib['options'])
        if diff:
            request(f'{base}/Library/VirtualFolders/LibraryOptions', 'POST', {'Id': folder['ItemId'], 'LibraryOptions': dict(folder['LibraryOptions'], **lib['options'])}, headers)
            log(f"CHANGED jellyfin library {lib['name']} options: {', '.join(diff)}")
    if refresh:
        request(f'{base}/Library/Refresh', 'POST', headers=headers)


def sync_jellyseerr(cfg):
    base = f"http://{HOST}:{cfg['port']}/api/v1"
    jellyfin = urllib.parse.urlparse(SPEC['jellyfin']['url'])
    if request(f'{base}/settings/public')['mediaServerType'] == 4:
        request(f'{base}/auth/jellyfin', 'POST', {'username': USER, 'password': PASSWORD, 'hostname': jellyfin.hostname, 'port': jellyfin.port,
                                                   'useSsl': False, 'urlBase': '', 'email': cfg['email'], 'serverType': 2})
        log('CHANGED seerr admin and jellyfin')
    headers = {'X-Api-Key': json.load(open(f'{CONFIGS}/jellyseerr/settings.json'))['main']['apiKey']}

    for library in request(f'{base}/settings/jellyfin/library/sync', 'POST', {}, headers):
        enabled = library['name'] in cfg['libraries']
        if library['enabled'] != enabled:
            request(f"{base}/settings/jellyfin/library/{library['id']}", 'PUT', {'enabled': enabled}, headers)
            log(f"CHANGED seerr library {library['name']} enabled={enabled}")

    diff = differs(request(f'{base}/settings/main', headers=headers), cfg['main'])
    if diff:
        request(f'{base}/settings/main', 'POST', cfg['main'], headers)
        log(f"CHANGED seerr main: {', '.join(diff)}")

    for kind, server in cfg['servers'].items():
        app = arr(kind)
        app_headers = {'X-Api-Key': arr_key(app['name'])}
        profiles = {p['name']: p['id'] for p in request(f"http://{HOST}:{app['port']}/api/v3/qualityprofile", headers=app_headers)}
        payload = {'name': app['prowlarr_name'], 'hostname': HOST, 'port': int(app['port']), 'apiKey': arr_key(app['name']), 'useSsl': False,
                   'baseUrl': '', 'activeProfileId': profiles[server['profile']], 'activeProfileName': server['profile'],
                   'activeDirectory': app['roots'][0], 'is4k': False, 'isDefault': True, 'syncEnabled': True, 'preventSearch': False,
                   'externalUrl': server['external_url']}
        payload.update(server.get('extra', {}))
        if 'anime_profile' in server:
            payload.update({'activeAnimeProfileId': profiles[server['anime_profile']], 'activeAnimeProfileName': server['anime_profile'],
                            'activeAnimeDirectory': app['roots'][1]})
        upsert(f'{base}/settings/{kind}', request(f'{base}/settings/{kind}', headers=headers), lambda s: s['name'] == payload['name'], payload, headers, f'seerr {kind}')

    if not request(f'{base}/settings/public')['initialized']:
        request(f'{base}/settings/initialize', 'POST', {}, headers)
        log('CHANGED seerr initialized')


if __name__ == '__main__':
    failed = False
    for step in SPEC['steps']:
        try:
            globals()[f'sync_{step}'](SPEC[step])
        except Exception as err:
            detail = err.read().decode()[:300] if isinstance(err, urllib.error.HTTPError) else repr(err)
            log(f'FAILED {step}: {detail}')
            failed = True
    sys.exit(1 if failed else 0)
