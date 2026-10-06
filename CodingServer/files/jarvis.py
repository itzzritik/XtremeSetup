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
NAME = os.environ.get('JARVIS_NAME', '')
STATE = os.environ['JARVIS_STATE']
TOKEN = os.environ.get('JARVIS_TOKEN', '')
MEDIA = os.environ['JARVIS_MEDIA_URL']
REQUEST = os.environ['JARVIS_REQUEST_URL']
VOICE = ('You are Jarvis, speaking through Siri. Answer in one to three short spoken sentences of plain text, with no formatting, lists or links. '
         'Skip greetings, never mention connectors, logins or setup issues, and ask before doing anything that changes something. '
         'When asked to open, play or show one title, end with [open:jellyfin:ITEM_ID] if it is in the Jellyfin library, else [open:movie:TMDB_ID] or [open:tv:TMDB_ID].')
AGENTS = {'claude': 'Claude Code', 'antigravity': 'Antigravity', 'codex': 'Codex', 'opencode': 'OpenCode'}
ALIASES = {
    'claude': r'\b(claude|claud|cloud)\b',
    'antigravity': r'\b(agy|aggie|a g y|antigravity|anti gravity|gemini)\b',
    'codex': r'\bcodex\b',
    'opencode': r'\bopen ?code\b',
}
LINKS = {'jellyfin': f'{MEDIA}/web/#/details?id={{}}', 'movie': f'{REQUEST}/movie/{{}}', 'tv': f'{REQUEST}/tv/{{}}'}
ASKS = ["what's up?", 'what do you need?', "what's on your mind?", 'how can I help?', 'what can I do for you?']
GOODBYE = re.compile(r"^\W*(done|stop|thanks|thank you|that'?s all|bye|goodbye)\W*$", re.I)
NEW_TOPIC = re.compile(r'^\W*(new (topic|conversation|chat)|start over|reset)\b', re.I)
SWITCH = re.compile(r'^\W*(switch|change)\b', re.I)
OPEN = re.compile(r'\[open:(jellyfin|movie|tv):([\w-]+)\]', re.I)
TURN_TIMEOUT = 55
POLL = 0.1

lock = threading.Lock()


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


def api(path, body=None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(f'{API}{path}', data=data, headers={'content-type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=30) as res:
            return res.status, json.loads(res.read() or b'{}').get('data')
    except urllib.error.HTTPError as err:
        return err.code, None


def conversation():
    if state.get('conversation') and api(f"/conversations/{state['conversation']}")[0] == 200:
        return state['conversation']
    agent = lambda a: (a.get('agent') or {}).get('acp_backend') or (a.get('agent') or {}).get('type')
    match = next((a for a in api('/assistants')[1] or [] if a.get('source') == 'generated' and agent(a) == state['agent']), None)
    if not match:
        raise RuntimeError(f"{AGENTS[state['agent']]} is not available")
    state['conversation'] = api('/conversations', {'assistant': {'id': match['id']}, 'name': 'Jarvis', 'extra': {'session_mode': 'yolo'}})[1]['id']
    save()
    return state['conversation']


def busy(cid):
    return bool(((api(f'/conversations/{cid}')[1] or {}).get('runtime') or {}).get('is_processing'))


def latest(cid):
    return api(f'/conversations/{cid}/messages/latest?type=text')[1] or {}


def send(cid, text):
    for _ in range(300):
        if not busy(cid):
            status, data = api(f'/conversations/{cid}/messages', {'content': f'{VOICE}\n\n{text}'})
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
    return 'Still working on that. Ask me again in a moment.'


def speakable(text):
    text = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', text)
    text = re.sub(r'^\s*[-•*]\s+', '', text, flags=re.M)
    text = re.sub(r'[*_`#>|]', '', text)
    return re.sub(r'\s+', ' ', text).strip() or 'Done.'


def greeting():
    hour = datetime.now().hour
    part = 'Hey' if hour < 5 else 'Morning' if hour < 12 else 'Afternoon' if hour < 17 else 'Evening'
    return f'{part} {NAME}, {random.choice(ASKS)}'


def ask(text):
    if GOODBYE.match(text):
        return {'say': 'Goodbye.'}
    agent = SWITCH.match(text) and next((name for name, pattern in ALIASES.items() if re.search(pattern, text, re.I)), None)
    if agent:
        state.update(agent=agent, conversation=None)
        save()
        return {'say': f'Switched to {AGENTS[agent]}.'}
    if NEW_TOPIC.match(text):
        state['conversation'] = None
        save()
        return {'say': 'Okay, starting fresh.'}
    cid = conversation()
    previous = latest(cid).get('id')
    send(cid, text)
    answer = reply(cid, previous)
    result = {'say': speakable(re.sub(r'\[open:[^\]]*\]', '', answer, flags=re.I))}
    if found := OPEN.search(answer):
        result['open'] = LINKS[found[1].lower()].format(found[2])
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
        if self.path == '/wake':
            threading.Thread(target=warm, daemon=True).start()
            return self.respond(200, greeting().encode())
        if self.path != '/ask':
            return self.respond(404)
        try:
            text = str(json.loads(self.rfile.read(int(self.headers.get('content-length') or 0)) or b'{}').get('text', '')).strip()
        except (ValueError, AttributeError):
            text = ''
        result = {'say': "I didn't catch that."}
        if text:
            with lock:
                try:
                    result = ask(text)
                except Exception as err:
                    result = {'say': f'Sorry, {err}.'}
        self.respond(200, json.dumps(result).encode(), 'application/json')


if __name__ == '__main__':
    ThreadingHTTPServer.daemon_threads = True
    ThreadingHTTPServer(('127.0.0.1', int(os.environ['JARVIS_PORT'])), Handler).serve_forever()
