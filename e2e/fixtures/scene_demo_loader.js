// Scene Demo loader for JS target
import { initWebGPU, setupGlobalState, loadGameScript } from "./lib/kagura-init.js";

async function init() {
  const result = await initWebGPU("#app");
  if (result) {
    setupGlobalState(result.canvas, result.device, result.format, result.context);
  }
  await loadGameScript("/examples/scene_demo/_build/js/debug/build/scene_demo.js");
}

init().catch(console.error);
