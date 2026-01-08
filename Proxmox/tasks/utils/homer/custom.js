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

	const serviceStatus = new Map();
	let isUpdating = false;

	const checkServiceStatus = async (url) => {
		const endpoint = url.replace(/\/$/, '');
		const cached = serviceStatus.get(endpoint);
		if (cached && Date.now() - cached.timestamp < 30000) return cached.status;
		const status = await isReachable(endpoint, 5000);
		serviceStatus.set(endpoint, { status, timestamp: Date.now() });
		return status;
	};

	const STATUS_STATES = {
		checking: { text: 'CHECKING', class: 'status-checking' },
		online: { text: 'ONLINE', class: 'status-online' },
		offline: { text: 'OFFLINE', class: 'status-offline' },
	};

	const setTagStatus = (tag, status) => {
		const state = STATUS_STATES[status];
		if (!state) return;

		let tagText = tag.querySelector('.tag-text');
		if (!tagText) {
			tagText = document.createElement('span');
			tagText.className = 'tag-text';
			tag.appendChild(tagText);
		}

		if (tagText.textContent !== state.text || !tag.classList.contains(state.class)) {
			tagText.textContent = state.text;
			tag.className = `tag status-tag ${state.class}`;
		}
	};

	const updateServiceTags = async () => {
		if (isUpdating) return;
		isUpdating = true;

		for (const card of document.querySelectorAll('.card')) {
			const href = card.querySelector('a[href]')?.getAttribute('href')?.replace(/\/$/, '');
			if (!href) continue;

			let tag = card.querySelector('.tag');
			if (!tag) {
				tag = document.createElement('div');
				tag.className = 'tag';
				card.querySelector('.card-content')?.appendChild(tag);
			}

			const service = Object.values(services).find((s) => {
				const url = mode === 'ip' ? s.ip : s.domain;
				return url.replace(/\/$/, '') === href;
			});

			if (service) {
				const serviceUrl = mode === 'ip' ? service.ip : service.domain;
				setTagStatus(tag, 'checking');
				const isOnline = await checkServiceStatus(serviceUrl);
				setTagStatus(tag, isOnline ? 'online' : 'offline');
			}
		}

		isUpdating = false;
	};

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
		const ICONS = {
			ip: { icon: 'fa-globe', text: 'Switch to Internet' },
			domain: { icon: 'fa-wifi', text: 'Switch to Local Network' },
		};

		const tooltip = Object.assign(document.createElement('div'), {
			className: 'url-switcher-tooltip',
			textContent: ICONS[mode].text,
		});

		const button = Object.assign(document.createElement('button'), {
			className: 'url-switcher-fab',
			innerHTML: `<i class="fas ${ICONS[mode].icon}"></i>`,
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
				button.innerHTML = `<i class="fas ${ICONS[mode].icon}"></i>`;
				tooltip.textContent = ICONS[mode].text;
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
	setTimeout(updateServiceTags, 500);
	setInterval(updateServiceTags, 60000);

	new MutationObserver((mutations) => {
		updateLinks();

		const isTagMutation = mutations.some((mutation) => {
			if (mutation.target.classList?.contains('tag') || mutation.target.classList?.contains('status-tag')) return true;
			const nodes = [...mutation.addedNodes, ...mutation.removedNodes];
			return nodes.some(node => node.classList?.contains('tag') || node.classList?.contains('status-tag'));
		});

		if (!isTagMutation) {
			clearTimeout(window.statusUpdateTimeout);
			window.statusUpdateTimeout = setTimeout(updateServiceTags, 500);
		}
	}).observe(document.body, { childList: true, subtree: true });
})();
