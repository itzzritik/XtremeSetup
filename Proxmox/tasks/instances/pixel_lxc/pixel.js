if (!location.hash && location.search !== '?list') {
    const ws = new URL('/', location.href);
    ws.protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws.search = new URLSearchParams({ action: 'proxy-adb', remote: 'tcp:8886', udid: 'pixel:5555' });
    location.replace('/#!' + new URLSearchParams({ action: 'stream', udid: 'pixel:5555', player: 'webcodecs', ws: ws.href }));
}

addEventListener('DOMContentLoaded', () => {
    const fab = document.createElement('button');
    fab.id = 'pixel-fab';
    fab.title = 'Controls';
    fab.textContent = '⋮';
    fab.onclick = () => document.body.classList.toggle('pixel-tools');
    document.body.appendChild(fab);
});

const wanted = () => {
    const portrait = innerHeight > innerWidth;
    const ratio = innerHeight / innerWidth;
    let width = portrait ? 1080 : 2560;
    let height = Math.round((width * ratio) / 8) * 8;
    // tablet layout needs at least 600dp (1200px at 320dpi) on the short side
    if (!portrait && height < 1200) {
        height = 1200;
        width = Math.round(height / ratio / 8) * 8;
    }
    return { width, height, dpi: portrait ? 420 : 320, nav: portrait ? 'threebutton' : 'gestural' };
};

const shell = (command) => new Promise((done) => {
    let out = '';
    const ws = new WebSocket(`${location.protocol === 'https:' ? 'wss:' : 'ws:'}//${location.host}/?action=shell`);
    ws.binaryType = 'arraybuffer';
    ws.onmessage = (e) => {
        out += typeof e.data === 'string' ? e.data : new TextDecoder().decode(e.data);
    };
    ws.onopen = () => {
        ws.send(JSON.stringify({ id: 1, type: 'shell', data: { type: 'start', rows: 24, cols: 200, udid: 'pixel:5555' } }));
        setTimeout(() => ws.send(`${command}; exit\r`), 800);
    };
    const finish = () => done(out.replace(/\x1b\[[0-9;?]*[a-zA-Z]/g, ''));
    ws.onclose = finish;
    setTimeout(finish, 8000);
});

const current = (out) => {
    const size = out.match(/Override size: (\d+)x(\d+)/) || out.match(/Physical size: (\d+)x(\d+)/);
    const dpi = out.match(/Override density: (\d+)/) || out.match(/Physical density: (\d+)/);
    const nav = out.match(/\[x\] com\.android\.internal\.systemui\.navbar\.(\w+)/);
    return { width: size && Number(size[1]), height: size && Number(size[2]), dpi: dpi && Number(dpi[1]), nav: nav && nav[1] };
};

const guard = (set) => {
    try {
        if (set) {
            sessionStorage.setItem('pixel-resized', String(Date.now()));
        }
        return Date.now() - Number(sessionStorage.getItem('pixel-resized') || 0) < 15000;
    } catch {
        return false;
    }
};

let checking = false;
const check = async () => {
    if (checking || document.visibilityState !== 'visible' || guard(false)) {
        return;
    }
    checking = true;
    const want = wanted();
    const now = current(await shell('wm size; wm density; cmd overlay list | grep navbar'));
    const resize = !now.width || Math.abs(now.width / now.height - want.width / want.height) / (want.width / want.height) > 0.03;
    if (resize || now.dpi !== want.dpi || now.nav !== want.nav) {
        guard(resize);
        await shell(`settings put system user_rotation 0; ${resize ? `wm size ${want.width}x${want.height}; ` : ''}wm density ${want.dpi}; ` +
            `cmd overlay enable-exclusive --category com.android.internal.systemui.navbar.${want.nav}`);
        if (resize) {
            setTimeout(() => location.reload(), 1500);
        }
    }
    checking = false;
};

let resizeTimer;
addEventListener('load', () => setTimeout(check, 1500));
addEventListener('resize', () => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(check, 1500);
});
