import { timingSafeEqual } from 'node:crypto';

const { AIONUI_URL, JARVIS_MEDIA_URL, JARVIS_NAME = '', JARVIS_PORT, JARVIS_REQUEST_URL, JARVIS_STATE, JARVIS_TOKEN = '' } = process.env;
const VOICE = 'You are Jarvis, speaking through Siri. Answer in one to three short spoken sentences of plain text, with no formatting, lists or links. Skip greetings, never mention connectors, logins or setup issues, and ask before doing anything that changes something. When asked to open, play or show one title, end with [open:jellyfin:ITEM_ID] if it is in the Jellyfin library, else [open:movie:TMDB_ID] or [open:tv:TMDB_ID].';
const AGENTS: Record<string, string> = { claude: 'Claude Code', antigravity: 'Antigravity', codex: 'Codex', opencode: 'OpenCode' };
const ALIASES: [RegExp, string][] = [
    [/\b(claude|claud|cloud)\b/i, 'claude'],
    [/\b(agy|aggie|a g y|antigravity|anti gravity|gemini)\b/i, 'antigravity'],
    [/\bcodex\b/i, 'codex'],
    [/\bopen ?code\b/i, 'opencode'],
];
const TURN_TIMEOUT = 55_000;
const LINKS: Record<string, (id: string) => string> = {
    jellyfin: (id) => `${JARVIS_MEDIA_URL}/web/#/details?id=${id}`,
    movie: (id) => `${JARVIS_REQUEST_URL}/movie/${id}`,
    tv: (id) => `${JARVIS_REQUEST_URL}/tv/${id}`,
};

type State = { agent: string; conversation?: string };
type Turn = { text: string; reply?: string; error?: string };

const state: State = await Bun.file(JARVIS_STATE!).json().catch(() => ({ agent: 'claude' }));
const turns = new Map<string, Turn>();
let queue: Promise<unknown> = Promise.resolve();

const save = () => Bun.write(JARVIS_STATE!, JSON.stringify(state));

async function api(path: string, body?: unknown) {
    const init = body === undefined ? undefined : { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body) };
    const res = await fetch(`${AIONUI_URL}/api${path}`, init);
    const json: any = await res.json().catch(() => ({}));
    return { status: res.status, data: json.data };
}

function listen() {
    const ws = new WebSocket(`${AIONUI_URL!.replace(/^http/, 'ws')}/ws`);
    ws.onmessage = (event) => {
        let message: any;
        try {
            message = JSON.parse(String(event.data));
        } catch {
            return;
        }
        const { name, data } = message;
        if (name === 'ping') return ws.send(JSON.stringify({ name: 'pong', data: {} }));
        if (name !== 'message.stream' || data?.conversation_id !== state.conversation) return;
        const turn = turns.get(data.turn_id) ?? { text: '' };
        turns.set(data.turn_id, turn);
        if (turns.size > 50) turns.delete(turns.keys().next().value!);
        if (data.type === 'tool_call' || data.type === 'acp_tool_call') turn.text = '';
        if (data.type === 'content') turn.text += data.data?.content ?? '';
        if (data.type === 'finish') turn.reply = turn.text;
        if (data.type === 'error') turn.error = data.data?.message ?? 'the agent failed';
    };
    ws.onclose = () => setTimeout(listen, 1000);
}

async function conversation() {
    if (state.conversation && (await api(`/conversations/${state.conversation}`)).status === 200) return state.conversation;
    const assistant = ((await api('/assistants')).data ?? []).find(
        (a: any) => a.source === 'generated' && (a.agent?.acp_backend ?? a.agent?.type) === state.agent,
    );
    if (!assistant) throw new Error(`${AGENTS[state.agent]} is not available`);
    state.conversation = (await api('/conversations', { assistant: { id: assistant.id }, name: 'Jarvis', extra: { session_mode: 'yolo' } })).data.id;
    await save();
    return state.conversation!;
}

async function send(id: string, text: string) {
    for (let i = 0; i < 300; i++) {
        if (!(await api(`/conversations/${id}`)).data?.runtime?.is_processing) {
            const sent = await api(`/conversations/${id}/messages`, { content: `${VOICE}\n\n${text}` });
            if (sent.data?.turn_id) return sent.data.turn_id as string;
            if (sent.status !== 409) throw new Error(`AionUi refused the message (${sent.status})`);
        }
        await Bun.sleep(100);
    }
    throw new Error('the agent is still busy');
}

async function reply(turnId: string) {
    for (const deadline = Date.now() + TURN_TIMEOUT; Date.now() < deadline; await Bun.sleep(50)) {
        const turn = turns.get(turnId);
        if (turn?.error) throw new Error(turn.error);
        if (turn?.reply !== undefined) return turn.reply;
    }
    return 'Still working on that. Ask me again in a moment.';
}

function greeting() {
    const hour = new Date().getHours();
    const part = hour < 5 ? 'Hey' : hour < 12 ? 'Morning' : hour < 17 ? 'Afternoon' : 'Evening';
    const asks = ["what's up?", 'what do you need?', "what's on your mind?", 'how can I help?', 'what can I do for you?'];
    return `${part} ${JARVIS_NAME}, ${asks[Math.floor(Math.random() * asks.length)]}`;
}

const speakable = (text: string) =>
    text.replace(/\[([^\]]+)\]\([^)]*\)/g, '$1').replace(/^\s*[-•*]\s+/gm, '').replace(/[*_`#>|]/g, '').replace(/\s+/g, ' ').trim() || 'Done.';

async function ask(text: string) {
    if (/^\W*(done|stop|thanks|thank you|that'?s all|bye|goodbye)\W*$/i.test(text)) return { say: 'Goodbye.' };
    const agent = /^\W*(switch|change)\b/i.test(text) && ALIASES.find(([pattern]) => pattern.test(text))?.[1];
    if (agent) {
        Object.assign(state, { agent, conversation: undefined });
        await save();
        return { say: `Switched to ${AGENTS[agent]}.` };
    }
    if (/^\W*(new (topic|conversation|chat)|start over|reset)\b/i.test(text)) {
        state.conversation = undefined;
        await save();
        return { say: 'Okay, starting fresh.' };
    }
    const answer = await reply(await send(await conversation(), text));
    const [, kind, id] = answer.match(/\[open:(jellyfin|movie|tv):([\w-]+)\]/i) ?? [];
    return { say: speakable(answer.replace(/\[open:[^\]]*\]/gi, '')), open: kind ? LINKS[kind.toLowerCase()](id) : undefined };
}

function authorized(req: Request) {
    const got = Buffer.from(req.headers.get('authorization') ?? '');
    const want = Buffer.from(`Bearer ${JARVIS_TOKEN}`);
    return JARVIS_TOKEN !== '' && got.length === want.length && timingSafeEqual(got, want);
}

listen();

Bun.serve({
    hostname: '127.0.0.1',
    port: Number(JARVIS_PORT),
    idleTimeout: 120,
    async fetch(req) {
        const { pathname } = new URL(req.url);
        if (pathname === '/health') return new Response(null, { status: (await api('/assistants')).status === 200 ? 200 : 503 });
        if (!authorized(req)) return new Response('Unauthorized', { status: 401 });
        if (req.method !== 'POST') return new Response('Not found', { status: 404 });
        if (pathname === '/wake') {
            queue = queue.then(() => conversation()).then((id) => api(`/conversations/${id}/runtime/ensure`, {})).catch(() => {});
            return new Response(greeting(), { headers: { 'content-type': 'text/plain; charset=utf-8' } });
        }
        if (pathname !== '/ask') return new Response('Not found', { status: 404 });
        const text = String((await req.json().catch(() => ({})))?.text ?? '').trim();
        if (!text) return Response.json({ say: "I didn't catch that." });
        const answer = queue.then(() => ask(text)).catch((error) => ({ say: `Sorry, ${error.message}.` }));
        queue = answer;
        return Response.json(await answer);
    },
});
