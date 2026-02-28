#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${1:?Usage: bash scripts/dev.sh <example_name>}"
EXAMPLE_DIR="$ROOT/examples/$NAME"
PORT="${PORT:-8080}"

if [ ! -d "$EXAMPLE_DIR" ]; then
  echo "Error: examples/$NAME not found"
  echo "Available:"
  ls -1 "$ROOT/examples/"
  exit 1
fi

# Build
echo "Building $NAME ..."
(cd "$EXAMPLE_DIR" && moon build src --target js)

JS_PATH="$EXAMPLE_DIR/_build/js/debug/build/$NAME.js"
if [ ! -f "$JS_PATH" ]; then
  echo "Error: build output not found at $JS_PATH"
  exit 1
fi

# Create temp serve dir
SERVE_DIR=$(mktemp -d)
trap 'rm -rf "$SERVE_DIR"' EXIT

mkdir -p "$SERVE_DIR/lib"
cp "$ROOT/e2e/fixtures/lib/kagura-init.js" "$SERVE_DIR/lib/kagura-init.js"
cp "$ROOT/e2e/fixtures/lib/kagura-audio.js" "$SERVE_DIR/lib/kagura-audio.js"
cp "$ROOT/e2e/fixtures/lib/kagura-gfx.js" "$SERVE_DIR/lib/kagura-gfx.js"
cp "$JS_PATH" "$SERVE_DIR/$NAME.js"

# Copy assets if present
FONT_LOAD_SNIPPET=""
if [ -d "$EXAMPLE_DIR/assets" ]; then
  cp -r "$EXAMPLE_DIR/assets" "$SERVE_DIR/assets"
  # Auto-detect TTF files for font preloading
  FONT_ENTRIES=""
  for ttf in "$SERVE_DIR/assets/"*.ttf; do
    [ -f "$ttf" ] || continue
    fname=$(basename "$ttf")
    key="assets/$fname"
    if [ -n "$FONT_ENTRIES" ]; then FONT_ENTRIES="$FONT_ENTRIES, "; fi
    FONT_ENTRIES="${FONT_ENTRIES}[\"$key\", \"./assets/$fname\"]"
  done
  if [ -n "$FONT_ENTRIES" ]; then
    FONT_LOAD_SNIPPET="  await loadFonts([$FONT_ENTRIES]);"
  fi
fi

# Generate loader
cat > "$SERVE_DIR/loader.js" <<LOADER
import { initWebGPU, setupGlobalState, loadFonts, loadGameScript } from "./lib/kagura-init.js";
import { installAudioHelpers } from "./lib/kagura-audio.js";
import { installGfxHelpers } from "./lib/kagura-gfx.js";
async function init() {
  const result = await initWebGPU("#app");
  if (result) setupGlobalState(result.canvas, result.device, result.format, result.context);
  installAudioHelpers();
  installGfxHelpers();
${FONT_LOAD_SNIPPET}
  await loadGameScript("./${NAME}.js");
}
init().catch(console.error);
LOADER

# Generate HTML
TITLE="${NAME//_/ }"
cat > "$SERVE_DIR/index.html" <<HTML
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>${TITLE} - Kagura Dev</title>
    <style>
      body {
        margin: 0;
        background: #000;
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
      }
      #app { border: 1px solid #444; }
    </style>
  </head>
  <body>
    <canvas id="app" width="320" height="240"
      style="width: 640px; height: 480px; image-rendering: pixelated"></canvas>
    <script type="module" src="./loader.js"></script>
  </body>
</html>
HTML

echo "Serving $NAME at http://localhost:$PORT"
echo "Press Ctrl+C to stop."

# Serve (prefer node for reliable MIME types)
if command -v node &>/dev/null; then
  node -e "
    const http = require('http');
    const fs = require('fs');
    const path = require('path');
    const TYPES = {'.html':'text/html','.js':'text/javascript','.mjs':'text/javascript','.ttf':'font/ttf','.wasm':'application/wasm'};
    http.createServer((req, res) => {
      let p = path.join('$SERVE_DIR', new URL(req.url, 'http://localhost').pathname);
      if (fs.existsSync(p) && fs.statSync(p).isDirectory()) p = path.join(p, 'index.html');
      if (!fs.existsSync(p) || !fs.statSync(p).isFile()) { res.writeHead(404); res.end('not found'); return; }
      res.writeHead(200, {'content-type': TYPES[path.extname(p)] || 'application/octet-stream', 'cache-control': 'no-store'});
      res.end(fs.readFileSync(p));
    }).listen($PORT, () => console.log('Ready'));
  "
elif command -v python3 &>/dev/null; then
  cd "$SERVE_DIR" && python3 -m http.server "$PORT"
else
  echo "Error: node or python3 required to serve"
  exit 1
fi
