#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$ROOT/_site"
EXAMPLES=(scene_demo flappy_bird survivor action_rpg arena3d runtime_smoke)
CACHE_BUST="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || date +%s)"

# Clean
rm -rf "$SITE"
mkdir -p "$SITE/lib"

# Build each example
for name in "${EXAMPLES[@]}"; do
  echo "Building $name ..."
  (cd "$ROOT/examples/$name" && moon build src --target js)
done

# Copy shared lib
cp "$ROOT/e2e/fixtures/lib/kagura-init.js" "$SITE/lib/kagura-init.js"
cp "$ROOT/e2e/fixtures/lib/kagura-audio.js" "$SITE/lib/kagura-audio.js"
cp "$ROOT/e2e/fixtures/lib/kagura-gfx.js" "$SITE/lib/kagura-gfx.js"

# Generate per-example pages
for name in "${EXAMPLES[@]}"; do
  dir="$SITE/$name"
  mkdir -p "$dir"

  # Copy build output
  cp "$ROOT/examples/$name/_build/js/debug/build/$name.js" "$dir/$name.js"

  # Copy assets if present
  FONT_LOAD_SNIPPET=""
  if [ -d "$ROOT/examples/$name/assets" ]; then
    cp -r "$ROOT/examples/$name/assets" "$dir/assets"
    # Auto-detect TTF files for font preloading
    FONT_ENTRIES=""
    for ttf in "$dir/assets/"*.ttf; do
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

  # Generate loader.js
  cat > "$dir/loader.js" <<LOADER
import { initWebGPU, setupGlobalState, loadFonts, loadGameScript } from "../lib/kagura-init.js";
import { installAudioHelpers } from "../lib/kagura-audio.js";
import { installGfxHelpers } from "../lib/kagura-gfx.js";
async function init() {
  const result = await initWebGPU("#app");
  if (result) setupGlobalState(result.canvas, result.device, result.format, result.context);
  installAudioHelpers();
  installGfxHelpers();
${FONT_LOAD_SNIPPET}
  await loadGameScript("./${name}.js?v=${CACHE_BUST}");
}
init().catch(console.error);
LOADER

  # Generate index.html
  title="${name//_/ }"
  cat > "$dir/index.html" <<HTML
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>${title} - Kagura</title>
    <style>
      body {
        margin: 0;
        background: #000;
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
      }
      #app {
        border: 1px solid #444;
      }
    </style>
  </head>
  <body>
    <canvas id="app" width="320" height="240"
      style="width: 640px; height: 480px; image-rendering: pixelated"></canvas>
    <script type="module" src="./loader.js?v=${CACHE_BUST}"></script>
  </body>
</html>
HTML
done

# Generate landing page
cat > "$SITE/index.html" <<'LANDING'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Kagura Examples</title>
    <style>
      body {
        font-family: system-ui, sans-serif;
        max-width: 640px;
        margin: 2rem auto;
        padding: 0 1rem;
        color: #e0e0e0;
        background: #1a1a2e;
      }
      h1 { color: #fff; }
      a {
        color: #7ecfff;
        text-decoration: none;
      }
      a:hover { text-decoration: underline; }
      ul { list-style: none; padding: 0; }
      li {
        padding: 0.75rem 1rem;
        margin: 0.5rem 0;
        background: #16213e;
        border-radius: 8px;
      }
      .note {
        margin-top: 2rem;
        padding: 1rem;
        background: #0f3460;
        border-radius: 8px;
        font-size: 0.9rem;
      }
    </style>
  </head>
  <body>
    <h1>Kagura Examples</h1>
    <p>2D-first game engine for MoonBit. These demos require a WebGPU-capable browser (Chrome 113+, Edge 113+).</p>
    <ul>
      <li><a href="./scene_demo/">Scene Demo</a> — Minimal declarative API example</li>
      <li><a href="./flappy_bird/">Flappy Bird</a></li>
      <li><a href="./survivor/">Survivor</a></li>
      <li><a href="./action_rpg/">Action RPG</a></li>
      <li><a href="./arena3d/">Arena 3D</a> — Experimental</li>
      <li><a href="./runtime_smoke/">Runtime Smoke</a></li>
    </ul>
    <div class="note">
      Source: <a href="https://github.com/mizchi/kagura">github.com/mizchi/kagura</a>
    </div>
  </body>
</html>
LANDING

echo "Done! Site built at $SITE"
