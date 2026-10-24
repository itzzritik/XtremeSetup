FROM node:18-bookworm AS build
WORKDIR /src
RUN git clone --depth 1 --branch v0.8.1 https://github.com/NetrisTV/ws-scrcpy.git .
RUN sed -i 's/bitrate: 524288,/bitrate: 8388608,/; s/maxFps: 24,/maxFps: 30,/; s/new Size(480, 480)/new Size(1280, 1280)/' src/app/player/WebCodecsPlayer.ts \
 && sed -i '/if (!saved) {/{n;s/return false;/return true;/}' src/app/player/BasePlayer.ts \
 && sed -i "s/        elements.push(keyboard);/        keyboard.getElement().checked = matchMedia('(pointer: coarse)').matches;\n        client.setHandleKeyboardEvents(keyboard.getElement().checked);\n        elements.push(keyboard);/" src/app/googDevice/toolbox/GoogToolBox.ts \
 && grep -q 'bitrate: 8388608' src/app/player/WebCodecsPlayer.ts \
 && grep -A1 'if (!saved) {' src/app/player/BasePlayer.ts | grep -q 'return true;' \
 && grep -q 'client.setHandleKeyboardEvents(keyboard.getElement().checked);' src/app/googDevice/toolbox/GoogToolBox.ts \
 && sed -i 's/const width = (body.clientWidth - this.controlButtons.clientWidth) & ~15;/const scale = Math.min(devicePixelRatio, 2048 \/ Math.max(body.clientWidth, body.clientHeight));\n        const width = (body.clientWidth * scale) \& ~15;/; s/const height = body.clientHeight & ~15;/const height = (body.clientHeight * scale) \& ~15;/' src/app/googDevice/client/StreamClientScrcpy.ts \
 && grep -q 'const height = (body.clientHeight \* scale) & ~15;' src/app/googDevice/client/StreamClientScrcpy.ts \
 && sed -i 's/^    mw2List.push(RemoteShell);$/    mw2List.push(RemoteShell);\n    mwList.push(RemoteShell);/' src/server/index.ts \
 && grep -q 'mwList.push(RemoteShell);' src/server/index.ts
RUN npm install && npm run dist
WORKDIR /src/dist
RUN npm install --omit=dev

FROM node:18-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends adb && rm -rf /var/lib/apt/lists/*
COPY --from=build /src/dist /app
COPY pixel.css pixel.js /app/public/
RUN cd /app/public \
 && sed -i 's#</head>#<link rel="stylesheet" href="pixel.css"><script src="pixel.js"></script></head>#' index.html \
 && for f in bundle.js main.css pixel.css pixel.js; do sed -i "s#\"$f\"#\"$f?v=$(md5sum $f | cut -c1-8)\"#" index.html; done \
 && grep -q 'pixel.js?v=' index.html && grep -q 'bundle.js?v=' index.html
WORKDIR /app
EXPOSE 8000
CMD ["sh", "-c", "adb start-server; while :; do adb connect pixel:5555 >/dev/null 2>&1; sleep 10; done & exec node index.js"]
