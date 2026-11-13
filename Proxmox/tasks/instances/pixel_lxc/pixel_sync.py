#!/usr/bin/env python3
import base64
import hashlib
import json
import os
import re
import sqlite3
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

PHOTO_EXT = {'.jpg', '.jpeg', '.png', '.heic', '.heif', '.webp', '.gif', '.bmp', '.avif',
             '.dng', '.cr2', '.cr3', '.nef', '.arw', '.orf', '.rw2', '.raf'}
VIDEO_EXT = {'.mp4', '.mov', '.m4v', '.3gp', '.3g2', '.mkv', '.avi', '.mts', '.m2ts',
             '.wmv', '.webm', '.mpg', '.mpeg', '.asf'}
SIDECAR_EXT = {'.aae'}
SIDECAR_NAME = re.compile(r'IMG_A\d+\.DAT', re.IGNORECASE)
LIVE_IMAGE_EXT = {'.heic', '.heif', '.jpg', '.jpeg'}
LIVE_VIDEO_EXT = {'.mov', '.mp4'}
REQUIRED_COLUMNS = {
    'local_media': {'filepath', 'size_bytes', 'dedup_key'},
    'media': {'dedup_key', 'canonical_media_key', 'trash_timestamp', 'is_deleted'},
}
MERGE_PREFIX = '.merging-'
FINDER_COPY_XATTR = 'com.apple.finder.copy.source'
IN_CLOUD ="COALESCE(m.canonical_media_key, '') != '' AND COALESCE(m.trash_timestamp, 0) = 0 AND COALESCE(m.is_deleted, 0) = 0"


def log(msg):
    print(msg, flush=True)


def load_json(path, default):
    try:
        return json.loads(Path(path).read_text())
    except (OSError, ValueError):
        return default


def save_json(path, data):
    tmp = Path(f'{path}.tmp')
    tmp.write_text(json.dumps(data, indent=1, sort_keys=True))
    os.replace(tmp, path)


def run(cmd, timeout=120, stdin=None):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, input=stdin, check=False)


def android(cfg, script, timeout=120):
    return run(['docker', 'exec', '-i', cfg['container'], '/system/bin/sh', '-s'], timeout, script)


def sha1_key(path):
    digest = hashlib.sha1()
    with open(path, 'rb') as f:
        while block := f.read(1 << 20):
            digest.update(block)
    return base64.urlsafe_b64encode(digest.digest()).decode().rstrip('=')


def inode(path):
    try:
        return os.stat(path).st_ino
    except OSError:
        return None


def restart_android(cfg, health, now, why):
    if now - health.get('last_restart', 0) <= 3 * cfg['watchdog_seconds']:
        return
    log(f'watchdog: {why}, restarting container')
    run(['docker', 'restart', cfg['container']], 300)
    health['last_restart'] = now
    health['system_server'] = ''


def watchdog(cfg, state, now):
    health = state['health']
    try:
        booted, _, pid = android(cfg, 'getprop sys.boot_completed; pidof system_server', 30).stdout.partition('\n')
    except subprocess.TimeoutExpired:
        booted, pid = '', ''
    pid = pid.strip()
    started = run(['docker', 'inspect', '-f', '{{.State.StartedAt}}', cfg['container']], 30).stdout.strip()
    if booted.strip() == '1':
        previous = health.get('system_server'), health.get('started')
        health['system_server'], health['started'] = pid, started
        if previous[0] and pid != previous[0] and started == previous[1]:
            restart_android(cfg, health, now, 'android restarted its system on its own')
            return False
        host = str(inode(cfg['upload_dir']))
        if android(cfg, f"stat -c %i {cfg['camera_dir']}", 30).stdout.strip() != host:
            if android(cfg, f"stat -c %i {cfg['android_upload_src']}", 30).stdout.strip() != host:
                restart_android(cfg, health, now, 'uploading folder was replaced')
                return False
            # mounted after boot so it reaches the storage views Android builds at boot
            dst = cfg['android_upload_dir']
            android(cfg, f"mkdir -p {dst}; umount {dst} 2>/dev/null; mount --bind {cfg['android_upload_src']} {dst}", 30)
            state.pop('uploading', None)
            log('attached uploading folder to Android')
            return False
        health['last_ok'] = now
        return True
    health.setdefault('last_ok', now)
    if now - health['last_ok'] > cfg['watchdog_seconds']:
        restart_android(cfg, health, now, 'android not responding')
    return False


def open_db(cfg):
    db = Path(cfg['photos_db'])
    if not db.exists():
        return None, 'Google Photos is not set up yet'
    conn = sqlite3.connect(f'file:{db}?mode=ro', uri=True, timeout=30)
    for table, columns in REQUIRED_COLUMNS.items():
        if not columns <= {row[1] for row in conn.execute(f'PRAGMA table_info({table})')}:
            conn.close()
            return None, f'Google Photos database layout changed ({table})'
    return conn, ''


def in_cloud(conn, key):
    return conn.execute(f'SELECT 1 FROM media m WHERE m.dedup_key = ? AND {IN_CLOUD} LIMIT 1', (key,)).fetchone() is not None


def confirmed_in_cloud(conn, camera_dir):
    rows = conn.execute(
        f'SELECT l.filepath, l.size_bytes, l.dedup_key FROM local_media l JOIN media m ON m.dedup_key = l.dedup_key '
        f'WHERE l.filepath LIKE ? AND {IN_CLOUD}', (camera_dir + '/%',))
    return {Path(path).name: (size, key) for path, size, key in rows}


def finder_copying(path):
    try:
        return any(FINDER_COPY_XATTR in name for name in os.listxattr(path))
    except OSError:
        return False


def scan_drop(cfg, state, now):
    drop = Path(cfg['drop_dir'])
    skip = {Path(cfg['upload_dir'])}
    seen, found, busy = state['seen'], {}, {}
    for root, dirs, files in os.walk(drop):
        dirs[:] = [d for d in dirs if not d.startswith('.') and Path(root, d) not in skip]
        busy[root] = busy.get(os.path.dirname(root), False) or finder_copying(root)
        for name in files:
            path = Path(root, name)
            if name.startswith(MERGE_PREFIX):
                path.unlink()
                continue
            if name.startswith('.') or not (path.suffix.lower() in PHOTO_EXT | VIDEO_EXT or is_sidecar(path)):
                continue
            st = path.stat()
            entry = seen.get(str(path))
            if not entry or (entry['size'], entry['mtime']) != (st.st_size, st.st_mtime):
                entry = seen[str(path)] = {'size': st.st_size, 'mtime': st.st_mtime, 'since': now}
            # Finder pre-creates empty placeholders and fills them later
            found[path] = (st.st_size > 0 and now - entry['since'] >= cfg['stable_seconds']
                           and not busy[root] and not finder_copying(path))
    for key in [k for k in seen if Path(k) not in found]:
        del seen[key]
    return found


def content_ids(paths, seen):
    need = [p for p in paths if 'cid' not in seen[str(p)]]
    if need:
        out = run(['exiftool', '-j', '-q', '-ContentIdentifier', '-@', '-'], 600, '\n'.join(map(str, need))).stdout
        ids = {Path(r['SourceFile']): str(r.get('ContentIdentifier', '')) for r in json.loads(out or '[]')}
        for p in need:
            seen[str(p)]['cid'] = ids.get(p, '')
    return {p: seen[str(p)]['cid'] for p in paths}


def pair_live(stable, ids, skipped):
    groups = {}
    for p in stable:
        ext = p.suffix.lower()
        if ids.get(p) and str(p) not in skipped and ext in LIVE_IMAGE_EXT | LIVE_VIDEO_EXT:
            groups.setdefault(ids[p], ([], []))[ext in LIVE_VIDEO_EXT].append(p)
    partner = {}
    for images, videos in groups.values():
        for image in images:
            same = [v for v in videos if v.stem.lower() == image.stem.lower()]
            if same or (len(images) == 1 and len(videos) == 1):
                partner[image] = (same or videos)[0]
    return partner


def plan_ingest(cfg, state, stable, ids, now):
    partner = pair_live(stable, ids, state['skipped_movs'])
    paired_videos = set(partner.values())
    items = []
    for path in sorted(stable, key=lambda p: state['seen'][str(p)]['since']):
        cid, ext = ids.get(path, ''), path.suffix.lower()
        if str(path) in state['skipped_movs'] or path in paired_videos:
            continue
        if path in partner:
            items.append((path, partner[path]))
            continue
        if cid and ext in LIVE_IMAGE_EXT | LIVE_VIDEO_EXT and now - state['pair_wait'].setdefault(str(path), now) < cfg['pair_wait_seconds']:
            continue
        items.append((path, None))
    state['pair_wait'] = {k: v for k, v in state['pair_wait'].items() if Path(k).exists()}
    return items


def merge_pair(cfg, image, video):
    out = image.with_name(MERGE_PREFIX + image.name)
    try:
        result = run([cfg['motionphoto2'], '--input-image', str(image), '--input-video', str(video), '--output-file', str(out)], 600)
        tag = run(['exiftool', '-s3', '-XMP-GCamera:MotionPhoto', str(out)]).stdout.strip() if out.exists() else ''
    except subprocess.TimeoutExpired:
        return None, 'merge timed out'
    if result.returncode == 0 and out.exists() and out.stat().st_size > 0 and tag == '1':
        return out, ''
    out.unlink(missing_ok=True)
    return None, ((result.stderr or result.stdout).strip().splitlines() or ['merge failed'])[-1]


def move_no_overwrite(src, dst_dir, name):
    n, name = 0, Path(name)
    while True:
        dst = dst_dir / (name.name if n == 0 else f'{name.stem} ({n}){name.suffix}')
        try:
            os.link(src, dst)
            break
        except FileExistsError:
            n += 1
    os.unlink(src)
    return dst


def mark_emptied(state, drop, path):
    for parent in path.parents[:len(path.relative_to(drop).parts) - 1]:
        state['emptied'][str(parent)] = inode(parent)


def queued_keys(state, upload):
    cache, fresh = state['queue_keys'], {}
    for p in upload.iterdir():
        if p.is_file():
            st = p.stat()
            sig = [st.st_ino, st.st_size, st.st_mtime]
            fresh[p.name] = cache[p.name] if cache.get(p.name, [None])[0] == sig else [sig, sha1_key(p)]
    state['queue_keys'] = fresh
    return {key: name for name, (_, key) in fresh.items()}


def ingest(cfg, state, conn, now):
    drop, upload = Path(cfg['drop_dir']), Path(cfg['upload_dir'])
    scanned = scan_drop(cfg, state, now)
    stable = [p for p, ok in scanned.items() if ok and not is_sidecar(p)]
    ids = content_ids([p for p in stable if p.suffix.lower() in LIVE_IMAGE_EXT | LIVE_VIDEO_EXT], state['seen'])
    items = plan_ingest(cfg, state, stable, ids, now)
    queued = {(st.st_dev, st.st_ino) for st in (p.stat() for p in upload.iterdir() if p.is_file())}
    keys = queued_keys(state, upload)
    cloud = confirmed_in_cloud(conn, cfg['camera_dir'])
    room = cfg['batch_size'] - sum(1 for p in upload.iterdir() if p.is_file() and p.name not in cloud)
    for image, video in items:
        if room <= 0:
            break
        src, sources = image, [image]
        if video:
            merged, why = merge_pair(cfg, image, video)
            if merged:
                src, sources = merged, [image, video]
            else:
                state['skipped_movs'][str(video)] = f'merge failed: {why}'
                state['totals']['merge_failed'] = state['totals'].get('merge_failed', 0) + 1
                log(f'merge failed, uploading {image.name} alone, keeping {video.name}: {why}')
        st = src.stat()
        if (st.st_dev, st.st_ino) in queued:
            src.unlink()
            continue
        key = sha1_key(src)
        if key in keys:
            for p in {src, *sources}:
                p.unlink()
            for p in sources:
                mark_emptied(state, drop, p)
            log(f'removed {image.name}: same file already queued as {keys[key]}')
            continue
        if in_cloud(conn, key):
            for p in {src, *sources}:
                p.unlink()
            for p in sources:
                mark_emptied(state, drop, p)
            state['totals']['already_in_google'] = state['totals'].get('already_in_google', 0) + 1
            log(f'removed {image.name}: same file already in Google Photos')
            continue
        dst = move_no_overwrite(src, upload, image.name)
        keys[key] = dst.name
        if video and src != image:
            image.unlink()
            video.unlink()
            state['totals']['merged'] = state['totals'].get('merged', 0) + 1
        for p in sources:
            mark_emptied(state, drop, p)
        log(f'queued {dst.name}' + (f' (motion photo from {image.name} + {video.name})' if len(sources) == 2 else ''))
        room -= 1
    state['skipped_movs'] = {k: v for k, v in state['skipped_movs'].items() if Path(k).exists()}
    return scanned


def process_deletes(cfg, state, conn, now, blocked):
    upload, confirmed = Path(cfg['upload_dir']), state['confirmed']
    cloud = confirmed_in_cloud(conn, cfg['camera_dir'])
    present = {p.name: p for p in upload.iterdir() if p.is_file()}
    state['confirmed'] = confirmed = {k: v for k, v in confirmed.items() if k in present and k in cloud}
    for name, path in present.items():
        if name not in cloud:
            continue
        size, key = cloud[name]
        st = path.stat()
        if st.st_size != size:
            continue
        entry = confirmed.get(name)
        if not entry or (entry['ino'], entry['size'], entry['mtime']) != (st.st_ino, st.st_size, st.st_mtime):
            confirmed[name] = {'since': now, 'ino': st.st_ino, 'size': st.st_size, 'mtime': st.st_mtime}
            continue
        if blocked or now - entry['since'] < cfg['confirm_wait_seconds']:
            continue
        if not entry.get('verified'):
            if sha1_key(path) != key:
                log(f'fingerprint differs from Google copy, keeping {name}')
                continue
            entry['verified'] = True
        st = path.stat()
        if (st.st_ino, st.st_size, st.st_mtime) != (entry['ino'], entry['size'], entry['mtime']):
            continue
        if not cfg['delete']:
            log(f'would delete {name} (log-only mode)')
            continue
        path.unlink()
        del confirmed[name]
        state['totals']['deleted'] = state['totals'].get('deleted', 0) + 1
        state['last_deleted'] = {'name': name, 'at': now}
        log(f'deleted {name}: confirmed in Google Photos')


def is_sidecar(path):
    return path.suffix.lower() in SIDECAR_EXT or SIDECAR_NAME.fullmatch(path.name) is not None


def photo_key(path):
    return re.sub(r'^IMG_[EOA](?=\d)', 'IMG_', re.sub(r' \(\d+\)$', '', path.stem.upper()))


def clean_sidecars(cfg, state, found):
    upload = Path(cfg['upload_dir'])
    media = {photo_key(p) for p in upload.iterdir() if p.is_file()}
    media |= {photo_key(p) for p in found if not is_sidecar(p)}
    for path, ok in found.items():
        if not ok or not is_sidecar(path) or photo_key(path) in media:
            continue
        if not cfg['delete']:
            log(f'would delete {path.name} (its photos are all uploaded, log-only mode)')
            continue
        path.unlink()
        state['totals']['sidecars_deleted'] = state['totals'].get('sidecars_deleted', 0) + 1
        log(f'deleted {path.name}: its photos are all uploaded')


def prune_dirs(state):
    emptied = state['emptied']
    for d in sorted(emptied, key=len, reverse=True):
        if inode(d) == emptied[d]:
            try:
                if os.listdir(d) == ['.DS_Store']:
                    os.unlink(os.path.join(d, '.DS_Store'))
                os.rmdir(d)
            except OSError:
                pass
    state['emptied'] = {d: ino for d, ino in emptied.items() if inode(d) == ino}


def main(config_path):
    cfg = json.loads(Path(config_path).read_text())
    state = load_json(cfg['state_file'], {})
    for key in ('seen', 'pair_wait', 'skipped_movs', 'confirmed', 'totals', 'health', 'emptied', 'queue_keys'):
        state.setdefault(key, {})
    now = time.time()
    try:
        upload = Path(cfg['upload_dir'])
        if not upload.is_dir():
            upload.mkdir()
            upload.chmod(0o777)
            log('uploading folder was missing, recreated it')
        conn, blocked = open_db(cfg) if watchdog(cfg, state, now) else (None, 'Android is not ready')
        if conn:
            with conn:
                found = ingest(cfg, state, conn, now)
                process_deletes(cfg, state, conn, now, blocked)
            clean_sidecars(cfg, state, found)
            prune_dirs(state)
            conn.close()
            uploading = []
            for p in sorted(upload.iterdir()):
                st = p.stat()
                uploading.append([p.name, st.st_ino, st.st_size, st.st_mtime_ns])
            if uploading != state.get('uploading'):
                # Android's FUSE keeps stale entries for files changed outside it
                Path('/proc/sys/vm/drop_caches').write_text('2')
                scan = android(cfg, f"am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file://{cfg['camera_dir']}")
                if scan.returncode == 0:
                    state['uploading'] = uploading
        state['last_error'] = ''
    except Exception as e:
        state['last_error'] = f'{datetime.now(ZoneInfo(cfg["timezone"])):%-d %B %Y %H:%M} {e!r}'
        log(f'error: {e!r}')
    save_json(cfg['state_file'], state)


if __name__ == '__main__':
    main(sys.argv[1])
