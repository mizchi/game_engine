// Flappy Bird loader for JS target
// Pre-initialize WebGPU device before loading game code
const canvas = document.querySelector("#app");

async function init() {
  // Pre-initialize WebGPU if available
  if (navigator.gpu) {
    try {
      const adapter = await navigator.gpu.requestAdapter();
      if (adapter) {
        const device = await adapter.requestDevice();
        const format = navigator.gpu.getPreferredCanvasFormat();
        const context = canvas.getContext("webgpu");
        if (context) {
          context.configure({ device, format, alphaMode: "opaque" });
          // Store in global state for hooks to pick up
          const state = globalThis.__gameEngineWebRuntime ?? (globalThis.__gameEngineWebRuntime = {
            nextSurfaceId: 100,
            selector: "#app",
            canvas: null,
            surfaceId: 0,
            width: canvas.width,
            height: canvas.height,
            dpr: 1,
            webgpu: {
              context: null, device: null, format: "bgra8unorm",
              pending: null, _pipeline: null, _pipelineFormat: "",
              _uniformBGL: null, _texBGL: null,
              _defaultTexture: null, _defaultTexView: null, _defaultSampler: null,
              _drawResourceCache: null, _currentDraw: null, _pendingTexture: null,
              presentScheduled: false,
              clear: [0, 0, 0, 1], commands: [], textures: null, lastError: "",
            },
          });
          state.canvas = canvas;
          state.surfaceId = state.nextSurfaceId++;
          canvas.__gameEngineSurfaceId = state.surfaceId;
          state.webgpu.context = context;
          state.webgpu.device = device;
          state.webgpu.format = format;
        }
      }
    } catch (e) {
      console.warn("WebGPU pre-init failed:", e);
    }
  }
  // Load the game script via script tag (IIFE format, not ESM)
  await new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = "/_build/js/debug/build/examples/flappy_bird/flappy_bird.js";
    script.onload = resolve;
    script.onerror = reject;
    document.head.appendChild(script);
  });
}

init().catch(console.error);
