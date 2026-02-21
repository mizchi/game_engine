// Flappy Bird loader for JS target
import { initWebGPU, setupGlobalState, loadGameScript } from "./lib/game-engine-init.js";

async function init() {
  const result = await initWebGPU("#app");
  if (result) {
    setupGlobalState(result.canvas, result.device, result.format, result.context);
  }
  await loadGameScript("/_build/js/debug/build/examples/flappy_bird/flappy_bird.js");
}

init().catch(console.error);
