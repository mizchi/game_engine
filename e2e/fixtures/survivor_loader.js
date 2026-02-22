// Survivor loader for JS target
import { initWebGPU, setupGlobalState, loadGameScript } from "./lib/kagura-init.js";

async function init() {
  const result = await initWebGPU("#app");
  if (result) {
    setupGlobalState(result.canvas, result.device, result.format, result.context);
  }
  await loadGameScript("/_build/js/debug/build/examples/survivor/survivor.js");
}

init().catch(console.error);
