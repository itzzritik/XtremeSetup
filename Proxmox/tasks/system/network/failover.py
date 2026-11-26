#!/usr/bin/env python3
import ipaddress
import json
import re
import socket
import subprocess
import sys
import time
from pathlib import Path

ETH, WIFI, BRIDGE = sys.argv[1:4]
TABLE = '200'
FAILBACK_AFTER = 5
NET0_MAC = re.compile(r'^net0:.*?([0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5})', re.M)


def log(msg):
    print(msg, flush=True)


def run(*cmd, quiet=False):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode and not quiet:
        log(f'{" ".join(cmd)}: {result.stderr.strip()}')
    return result.stdout


def is_up(iface):
    try:
        return Path(f'/sys/class/net/{iface}/operstate').read_text().strip() == 'up'
    except OSError:
        return False


def mac(iface):
    return Path(f'/sys/class/net/{iface}/address').read_text().strip()


def lan():
    addr = json.loads(run('ip', '-j', '-4', 'addr', 'show', 'dev', BRIDGE))[0]['addr_info'][0]
    host = ipaddress.ip_interface(f"{addr['local']}/{addr['prefixlen']}")
    gateway = json.loads(run('ip', '-j', 'route', 'show', 'default'))[0]['gateway']
    return str(host.network), str(host.ip), gateway


def guests(host_ip):
    prefix = host_ip.rsplit('.', 1)[0]
    found = {}
    for conf in [*Path('/etc/pve/lxc').glob('*.conf'), *Path('/etc/pve/qemu-server').glob('*.conf')]:
        match = NET0_MAC.search(conf.read_text())
        if match:
            # ponytail: guest IP is <lan prefix>.<vmid>, the convention every instance task follows
            found[f'{prefix}.{conf.stem}'] = match.group(1).lower()
    return found


def announce(iface, owners):
    try:
        with socket.socket(socket.AF_PACKET, socket.SOCK_RAW) as sock:
            sock.bind((iface, 0))
            for _ in range(3):
                for ip, hw in owners.items():
                    m, a = bytes.fromhex(hw.replace(':', '')), socket.inet_aton(ip)
                    arp = b'\x00\x01\x08\x00\x06\x04\x00\x01' + m + a + bytes(6) + a
                    sock.send(b'\xff' * 6 + m + b'\x08\x06' + arp + bytes(18))
                time.sleep(1)
    except OSError as e:
        log(f'announce on {iface} failed: {e}')


def proxy_arp(on):
    for iface in (WIFI, BRIDGE):
        Path(f'/proc/sys/net/ipv4/conf/{iface}/proxy_arp').write_text('1' if on else '0')


def use_wifi():
    subnet, host_ip, gateway = lan()
    members = guests(host_ip)
    proxy_arp(True)
    run('ip', 'route', 'replace', subnet, 'dev', WIFI, 'src', host_ip, 'table', TABLE)
    run('ip', 'route', 'replace', 'default', 'via', gateway, 'dev', WIFI, 'onlink', 'table', TABLE)
    for ip in members:
        run('ip', 'route', 'replace', f'{ip}/32', 'dev', BRIDGE, 'table', TABLE)
    run('ip', 'rule', 'del', 'priority', TABLE, quiet=True)
    run('ip', 'rule', 'add', 'priority', TABLE, 'table', TABLE)
    announce(WIFI, dict.fromkeys([host_ip, *members], mac(WIFI)))


def use_ethernet(was_wifi):
    run('ip', 'rule', 'del', 'priority', TABLE, quiet=True)
    run('ip', 'route', 'flush', 'table', TABLE)
    proxy_arp(False)
    run('systemctl', 'stop', f'wpa_supplicant@{WIFI}')
    run('ip', 'link', 'set', WIFI, 'down')
    if was_wifi:
        _, host_ip, _ = lan()
        announce(BRIDGE, {host_ip: mac(BRIDGE), **guests(host_ip)})


def main():
    mode, eth_since, routed = None, None, False
    while True:
        if is_up(ETH):
            eth_since = eth_since or time.monotonic()
            if mode != 'ethernet' and time.monotonic() - eth_since >= FAILBACK_AFTER:
                use_ethernet(mode == 'wifi')
                mode = 'ethernet'
                log('on ethernet, wifi off')
        else:
            eth_since = None
            if mode != 'wifi':
                run('systemctl', 'start', f'wpa_supplicant@{WIFI}')
                mode, routed = 'wifi', False
                log('ethernet down, switching to wifi')
            if not routed and is_up(WIFI):
                use_wifi()
                routed = True
                log('wifi connected, now answering for host and guests')
        time.sleep(1)


if __name__ == '__main__':
    main()
