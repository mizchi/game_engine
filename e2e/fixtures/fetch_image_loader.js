// fetch_image loader for JS target E2E test
import { initWebGPU, setupGlobalState, loadGameScript } from "../../lib/web/kagura-init.js";

async function init() {
  let hasWebGPU = false;
  const result = await initWebGPU("#app");
  if (result) {
    setupGlobalState(result.canvas, result.device, result.format, result.context);
    hasWebGPU = true;
  }

  // Hook requestAnimationFrame to count frames
  let frames = 0;
  const origRAF = window.requestAnimationFrame.bind(window);
  window.requestAnimationFrame = (cb) => {
    return origRAF((ts) => {
      frames++;
      if (frames === 1) {
        // Expose result after first frame
        window.__fetchImageResult = { status: "ok", frames, hasWebGPU };
      }
      cb(ts);
      // Keep updating frame count
      window.__fetchImageResult = { ...window.__fetchImageResult, frames };
    });
  };

  await loadGameScript("/examples/fetch_image/_build/js/debug/build/fetch_image.js");

  // Fallback: if no frame rendered within 5s, report timeout
  setTimeout(() => {
    if (!window.__fetchImageResult) {
      window.__fetchImageResult = { status: "timeout", frames: 0, hasWebGPU };
    }
  }, 5000);
}

init().catch((err) => {
  console.error("fetch_image loader error:", err);
  window.__fetchImageResult = { status: "error", frames: 0, hasWebGPU: false, error: String(err) };
});
