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
LIVE_IMAGE_EXT = {'.heic', '.heif', '.jpg', '.jpeg'}
LIVE_VIDEO_EXT = {'.mov', '.mp4'}
REQUIRED_COLUMNS = {
    'local_media': {'filepath', 'size_bytes', 'dedup_key'},
    'media': {'dedup_key', 'canonical_media_key', 'trash_timestamp', 'is_deleted'},
}
IN_CLOUD = "COALESCE(m.canonical_media_key, '') != '' AND COALESCE(m.trash_timestamp, 0) = 0 AND COALESCE(m.is_deleted, 0) = 0"


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


def scan_drop(cfg, state, now):
    drop = Path(cfg['drop_dir'])
    skip = {Path(cfg['upload_dir']), Path(cfg['merge_tmp_dir'])}
    seen, found = state['seen'], {}
    for root, dirs, files in os.walk(drop):
        dirs[:] = [d for d in dirs if not d.startswith('.') and Path(root, d) not in skip]
        for name in files:
            path = Path(root, name)
            if name.startswith('.') or path.suffix.lower() not in PHOTO_EXT | VIDEO_EXT | SIDECAR_EXT:
                continue
            st = path.stat()
            entry = seen.get(str(path))
            if not entry or (entry['size'], entry['mtime']) != (st.st_size, st.st_mtime):
                entry = seen[str(path)] = {'size': st.st_size, 'mtime': st.st_mtime, 'since': now}
            found[path] = now - entry['since'] >= cfg['stable_seconds']
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
    items, waiting = [], 0
    for path in sorted(stable, key=lambda p: state['seen'][str(p)]['since']):
        cid, ext = ids.get(path, ''), path.suffix.lower()
        if str(path) in state['skipped_movs'] or str(path) in state['in_google'] or path in paired_videos:
            continue
        if path in partner:
            items.append((path, partner[path]))
            continue
        if cid and ext in LIVE_IMAGE_EXT | LIVE_VIDEO_EXT and now - state['pair_wait'].setdefault(str(path), now) < cfg['pair_wait_seconds']:
            waiting += 1
            continue
        items.append((path, None))
    state['pair_wait'] = {k: v for k, v in state['pair_wait'].items() if Path(k).exists()}
    return items, waiting


def merge_pair(cfg, image, video):
    out = Path(cfg['merge_tmp_dir']) / image.name
    try:
        result = run([cfg['motionphoto2'], '--input-image', str(image), '--input-video', str(video), '--output-file', str(out)], 600)
        tag = run(['exiftool', '-s3', '-XMP-GCamera:MotionPhoto', str(out)]).stdout.strip() if out.exists() else ''
    except subprocess.TimeoutExpired:
        return None, 'merge timed out'
    if result.returncode == 0 and out.exists() and out.stat().st_size > 0 and tag == '1':
        return out, ''
    out.unlink(missing_ok=True)
    return None, ((result.stderr or result.stdout).strip().splitlines() or ['merge failed'])[-1]


def move_no_overwrite(src, dst_dir):
    n = 0
    while True:
        dst = dst_dir / (src.name if n == 0 else f'{src.stem} ({n}){src.suffix}')
        try:
            os.link(src, dst)
            break
        except FileExistsError:
            n += 1
    os.unlink(src)
    return dst


def ingest(cfg, state, conn, now):
    upload, tmp = Path(cfg['upload_dir']), Path(cfg['merge_tmp_dir'])
    tmp.mkdir(exist_ok=True)
    for leftover in tmp.iterdir():
        leftover.unlink()
    found = {p: ok for p, ok in scan_drop(cfg, state, now).items() if p.suffix.lower() not in SIDECAR_EXT}
    stable = [p for p, ok in found.items() if ok]
    ids = content_ids([p for p in stable if p.suffix.lower() in LIVE_IMAGE_EXT | LIVE_VIDEO_EXT], state['seen'])
    items, waiting = plan_ingest(cfg, state, stable, ids, now)
    queued = {(st.st_dev, st.st_ino) for st in (p.stat() for p in upload.iterdir() if p.is_file())}
    room, moved = cfg['batch_size'] - len(queued), 0
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
        if in_cloud(conn, sha1_key(src)):
            state['in_google'][str(image)] = 'already in Google Photos'
            if src != image:
                src.unlink()
            log(f'already in Google Photos, keeping {image.name} in place')
            continue
        dst = move_no_overwrite(src, upload)
        if video and src != image:
            image.unlink()
            video.unlink()
            state['totals']['merged'] = state['totals'].get('merged', 0) + 1
        log(f'queued {dst.name}' + (f' (motion photo from {image.name} + {video.name})' if len(sources) == 2 else ''))
        room, moved = room - 1, moved + 1
    state['skipped_movs'] = {k: v for k, v in state['skipped_movs'].items() if Path(k).exists()}
    state['in_google'] = {k: v for k, v in state['in_google'].items() if Path(k).exists()}
    return {'moved': moved, 'waiting': len(found), 'live_waiting': waiting}


def process_deletes(cfg, state, conn, now, blocked):
    upload, confirmed = Path(cfg['upload_dir']), state['confirmed']
    cloud = confirmed_in_cloud(conn, cfg['camera_dir'])
    present = {p.name: p for p in upload.iterdir() if p.is_file()}
    state['confirmed'] = confirmed = {k: v for k, v in confirmed.items() if k in present and k in cloud}
    deleted = 0
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
        deleted += 1
        state['totals']['deleted'] = state['totals'].get('deleted', 0) + 1
        state['last_deleted'] = {'name': name, 'at': now}
        log(f'deleted {name}: confirmed in Google Photos')
    return deleted


def photo_key(path):
    return re.sub(r'^IMG_[EO](?=\d)', 'IMG_', re.sub(r' \(\d+\)$', '', path.stem.upper()))


def clean_sidecars(cfg, state, now):
    drop, upload = Path(cfg['drop_dir']), Path(cfg['upload_dir'])
    media, sidecars = {photo_key(p) for p in upload.iterdir() if p.is_file()}, []
    for root, dirs, files in os.walk(drop):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for name in files:
            path = Path(root, name)
            if path.suffix.lower() in SIDECAR_EXT:
                sidecars.append(path)
            elif path.suffix.lower() in PHOTO_EXT | VIDEO_EXT:
                media.add(photo_key(path))
    for path in sidecars:
        entry = state['seen'].get(str(path))
        if photo_key(path) in media or not entry or now - entry['since'] < cfg['stable_seconds']:
            continue
        if not cfg['delete']:
            log(f'would delete {path.name} (its photos are all uploaded, log-only mode)')
            continue
        path.unlink()
        state['totals']['sidecars_deleted'] = state['totals'].get('sidecars_deleted', 0) + 1
        log(f'deleted {path.name}: its photos are all uploaded')


def prune_dirs(cfg):
    drop, keep = Path(cfg['drop_dir']), {Path(cfg['upload_dir']), Path(cfg['merge_tmp_dir'])}
    for root, dirs, _ in os.walk(drop, topdown=False):
        for d in dirs:
            if not d.startswith('.') and Path(root, d) not in keep:
                try:
                    Path(root, d).rmdir()
                except OSError:
                    pass


def write_status(cfg, state, stats, now):
    def fmt(ts):
        return datetime.fromtimestamp(ts, ZoneInfo(cfg['timezone'])).strftime('%-d %B %Y, %-I:%M%p').replace('AM', 'am').replace('PM', 'pm')

    upload = Path(cfg['upload_dir'])
    last = state.get('last_deleted')
    lines = {
        'updated': fmt(now),
        'mode': 'live (deletes after confirmation)' if cfg['delete'] else 'log-only (nothing is deleted)',
        'android': 'healthy' if stats.get('healthy') else 'not ready',
        'waiting_in_pixel': stats.get('waiting', 0),
        'in_uploading': sum(1 for p in upload.iterdir() if p.is_file()) if upload.exists() else 0,
        'live_photos_merged_total': state['totals'].get('merged', 0),
        'live_photos_waiting_for_pair': stats.get('live_waiting', 0),
        'live_photo_videos_skipped': ', '.join(f'{Path(k).name} ({v})' for k, v in state['skipped_movs'].items()) or 'none',
        'already_in_google_kept': ', '.join(Path(k).name for k in state['in_google']) or 'none',
        'deleted_total': state['totals'].get('deleted', 0),
        'last_deleted': f"{last['name']} at {fmt(last['at'])}" if last else 'none',
        'deletes_blocked': stats.get('blocked') or 'no',
        'last_error': state.get('last_error') or 'none',
    }
    tmp = Path(cfg['status_file']).with_name('.STATUS.txt.tmp')
    tmp.write_text(''.join(f'{k}: {v}\n' for k, v in lines.items()))
    os.replace(tmp, cfg['status_file'])


def main(config_path):
    cfg = json.loads(Path(config_path).read_text())
    state = load_json(cfg['state_file'], {})
    for key in ('seen', 'pair_wait', 'skipped_movs', 'in_google', 'confirmed', 'totals', 'health'):
        state.setdefault(key, {})
    now, stats = time.time(), {}
    try:
        stats['healthy'] = watchdog(cfg, state, now)
        conn, stats['blocked'] = open_db(cfg) if stats['healthy'] else (None, 'Android is not ready')
        if conn:
            with conn:
                stats.update(ingest(cfg, state, conn, now))
                stats['deleted'] = process_deletes(cfg, state, conn, now, stats['blocked'])
            clean_sidecars(cfg, state, now)
            prune_dirs(cfg)
            conn.close()
            if stats.get('moved') or stats.get('deleted'):
                android(cfg, f"am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file://{cfg['camera_dir']}")
        state['last_error'] = ''
    except Exception as e:
        state['last_error'] = f'{datetime.now(ZoneInfo(cfg["timezone"])):%-d %B %Y %H:%M} {e!r}'
        log(f'error: {e!r}')
    write_status(cfg, state, stats, now)
    save_json(cfg['state_file'], state)


if __name__ == '__main__':
    main(sys.argv[1])
