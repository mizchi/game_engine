// Shared WebGPU initialization for JS-target game engine examples

export async function initWebGPU(canvasSelector) {
  const canvas = document.querySelector(canvasSelector);
  if (!canvas || !navigator.gpu) {
    return null;
  }
  try {
    const adapter = await navigator.gpu.requestAdapter();
    if (!adapter) return null;
    const device = await adapter.requestDevice();
    const format = navigator.gpu.getPreferredCanvasFormat();
    const context = canvas.getContext("webgpu");
    if (!context) return null;
    context.configure({ device, format, alphaMode: "opaque" });
    return { canvas, device, format, context };
  } catch (e) {
    console.warn("WebGPU init failed:", e);
    return null;
  }
}

export function setupGlobalState(canvas, device, format, context) {
  const state = globalThis.__kaguraWebRuntime ?? (globalThis.__kaguraWebRuntime = {
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
  canvas.__kaguraSurfaceId = state.surfaceId;
  state.webgpu.context = context;
  state.webgpu.device = device;
  state.webgpu.format = format;
  return state;
}

export function loadGameScript(scriptPath) {
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = scriptPath;
    script.onload = resolve;
    script.onerror = reject;
    document.head.appendChild(script);
  });
}
