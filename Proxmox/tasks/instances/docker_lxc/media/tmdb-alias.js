const https = require('https');

const FROM = 'api.themoviedb.org';
const TO = 'api.tmdb.org';

const swap = (target) => {
    if (typeof target === 'string') return target.replace(`//${FROM}`, `//${TO}`);
    if (target instanceof URL) return target.hostname === FROM ? new URL(target.href.replace(FROM, TO)) : target;
    if (target && typeof target === 'object') {
        for (const key of ['hostname', 'host', 'servername']) {
            if (target[key] === FROM) target[key] = TO;
        }
    }
    return target;
};

for (const name of ['request', 'get']) {
    const original = https[name];
    https[name] = function (input, options, callback) {
        return original.call(this, swap(input), swap(options), callback);
    };
}
