(async () => {
	'use strict';

	const parseConfig = (yaml) => {
		const extract = (pattern) => yaml.match(pattern)?.[1];

		const homerDomainUrl = extract(/homerDomainUrl:\s*"([^"]+)"/);
		const homerIpUrl = extract(/homerIpUrl:\s*"([^"]+)"/);
		if (!homerDomainUrl || !homerIpUrl) return null;

		const services = {};
		const itemRegex = /- name:.*?\n\s+subtitle:.*?\n\s+logo:.*?\n\s+url:\s*"([^"]+)".*?\n\s+endpoint:.*?\n\s+ip:\s*"([^"]+)"/g;

		for (const [, domain, ip] of yaml.matchAll(itemRegex)) {
			services[domain] = { domain, ip };
		}

		return { services, homerDomainUrl, homerIpUrl };
	};

	const loadConfig = async () => {
		try {
			const res = await fetch('./assets/config.yml');
			return res.ok ? parseConfig(await res.text()) : null;
		} catch (err) {
			console.error('Failed to load config:', err);
			return null;
		}
	};

	const isReachable = async (url, timeout = 3000) => {
		try {
			const controller = new AbortController();
			setTimeout(() => controller.abort(), timeout);
			await fetch(url, { method: 'HEAD', mode: 'no-cors', signal: controller.signal });
			return true;
		} catch {
			return false;
		}
	};

	const config = await loadConfig();
	if (!config) return;

	const { services, homerDomainUrl, homerIpUrl } = config;
	const isIP = /^(\d{1,3}\.){3}\d{1,3}$/.test(location.hostname);
	const mode = isIP ? 'ip' : 'domain';
	const targetUrl = mode === 'ip' ? homerDomainUrl : homerIpUrl;

	const updateLinks = () => {
		document.querySelectorAll('a[href]').forEach((link) => {
			const href = link.getAttribute('href')?.replace(/\/$/, '');
			if (!href) return;

			for (const { domain, ip } of Object.values(services)) {
				const target = mode === 'ip' ? ip : domain;
				if (href === domain.replace(/\/$/, '') || href === ip.replace(/\/$/, '')) {
					link.href = target;
					break;
				}
			}
		});
	};

	const createButton = () => {
		const icons = {
			ip: { normal: 'fa-globe', text: 'Switch to Domain' },
			domain: { normal: 'fa-network-wired', text: 'Switch to IP' },
		};

		const tooltip = Object.assign(document.createElement('div'), {
			className: 'url-switcher-tooltip',
			textContent: icons[mode].text,
		});

		const button = Object.assign(document.createElement('button'), {
			className: 'url-switcher-fab',
			innerHTML: `<i class="fas ${icons[mode].normal}"></i>`,
			onmouseenter: () => tooltip.classList.add('visible'),
			onmouseleave: () => tooltip.classList.remove('visible'),
		});

		document.body.append(tooltip, button);

		let checking = false;
		let reachable = null;

		const updateButton = async () => {
			if (checking) return;
			checking = true;

			button.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
			reachable = await isReachable(targetUrl);

			if (reachable) {
				button.disabled = false;
				button.innerHTML = `<i class="fas ${icons[mode].normal}"></i>`;
				tooltip.textContent = icons[mode].text;
			} else {
				button.disabled = true;
				button.innerHTML = '<i class="fas fa-exclamation-triangle"></i>';
				tooltip.textContent = 'Unreachable';
			}

			checking = false;
		};

		button.onclick = async () => {
			if (button.disabled || checking) return;
			if (reachable === null) await updateButton();
			else location.href = targetUrl;
		};

		setTimeout(updateButton, 1000);
		setInterval(updateButton, 30000);
	};

	updateLinks();
	createButton();
	setTimeout(updateLinks, 500);

	new MutationObserver(updateLinks).observe(document.body, {
		childList: true,
		subtree: true,
	});
})();
