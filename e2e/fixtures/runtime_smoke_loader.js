const statusElement = document.getElementById("status");
const outputElement = document.getElementById("output");
const wasmPath = document.documentElement.getAttribute("data-wasm-path");
const canvasSelector = document.documentElement.getAttribute("data-canvas-selector") ?? "#app";

const setStatus = (status) => {
  if (statusElement == null) {
    return;
  }
  statusElement.textContent = status;
  statusElement.dataset.state = status;
};

const setOutput = (output) => {
  if (outputElement == null) {
    return;
  }
  outputElement.textContent = output;
};

const webState = {
  selector: canvasSelector,
  nextSurfaceId: 100,
  surfaceId: 1,
  canvas: null,
  width: 640,
  height: 480,
  dpr: 1,
  backendMode: "webgpu",
  webgpu: {
    context: null,
    device: null,
    format: "bgra8unorm",
    pending: null,
  },
  webgl2: {
    context: null,
  },
      frame: {
        clear: [0, 0, 0, 1],
        drawCalls: 0,
        commandCount: 0,
        lastPipelineId: 0,
        lastUniformHash: 0,
        lastBlendMode: 1,
        lastDstImageId: 0,
        lastShaderId: 0,
        lastIndexOffset: 0,
        lastRegionCount: 0,
        lastTotalIndexCount: 0,
        lastVertexFloatCount: 0,
        lastIndexCount: 0,
        lastSrcImageCount: 0,
        lastUniformDwordCount: 0,
        payloadHasTriangle: false,
        payloadAx: 0,
        payloadAy: 0.5,
        payloadBx: -0.5,
        payloadBy: -0.5,
        payloadCx: 0.5,
        payloadCy: -0.5,
        payloadUniformR: 1,
        payloadUniformG: 1,
        payloadUniformB: 1,
        payloadUniformA: 1,
        payloadTextureSeed: 0,
        presentedFrames: 0,
      },
};

const toInt = (value) => (value ? 1 : 0);

const ensureCanvas = (fallbackWidth, fallbackHeight) => {
  const doc = typeof document === "undefined" ? null : document;
  if (doc == null || typeof doc.querySelector !== "function") {
    webState.canvas = null;
    webState.width = fallbackWidth;
    webState.height = fallbackHeight;
    webState.dpr = 1;
    webState.surfaceId = 1;
    return true;
  }
  const canvas = doc.querySelector(webState.selector);
  if (canvas == null || typeof canvas.getContext !== "function") {
    return false;
  }
  const canvasType = typeof HTMLCanvasElement === "undefined" ? null : HTMLCanvasElement;
  if (canvasType != null && !(canvas instanceof canvasType)) {
    return false;
  }
  const dpr = Number(globalThis.devicePixelRatio ?? 1) || 1;
  const rect = typeof canvas.getBoundingClientRect === "function"
    ? canvas.getBoundingClientRect()
    : { width: fallbackWidth, height: fallbackHeight };
  const cssWidth = rect.width > 0 ? rect.width : fallbackWidth;
  const cssHeight = rect.height > 0 ? rect.height : fallbackHeight;
  const pixelWidth = Math.max(1, Math.round(cssWidth * dpr));
  const pixelHeight = Math.max(1, Math.round(cssHeight * dpr));
  if (canvas.width !== pixelWidth) {
    canvas.width = pixelWidth;
  }
  if (canvas.height !== pixelHeight) {
    canvas.height = pixelHeight;
  }
  if (canvas.__gameEngineSurfaceId == null) {
    canvas.__gameEngineSurfaceId = webState.nextSurfaceId++;
  }
  webState.canvas = canvas;
  webState.surfaceId = Number(canvas.__gameEngineSurfaceId) | 0;
  webState.width = pixelWidth;
  webState.height = pixelHeight;
  webState.dpr = dpr;
  return true;
};

const ensureWebGpu = () => {
  const nav = typeof navigator === "undefined" ? null : navigator;
  if (webState.canvas == null || nav == null || nav.gpu == null) {
    return false;
  }
  const context = webState.canvas.getContext("webgpu");
  if (context == null) {
    return false;
  }
  webState.webgpu.context = context;
  if (webState.webgpu.device == null && webState.webgpu.pending == null) {
    webState.webgpu.pending = nav.gpu.requestAdapter()
      .then((adapter) => adapter == null ? null : adapter.requestDevice())
      .then((device) => {
        if (device == null) {
          return;
        }
        const format = typeof nav.gpu.getPreferredCanvasFormat === "function"
          ? nav.gpu.getPreferredCanvasFormat()
          : "bgra8unorm";
        webState.webgpu.format = format;
        webState.webgpu.device = device;
      })
      .catch(() => {
        webState.webgpu.device = null;
      })
      .finally(() => {
        webState.webgpu.pending = null;
      });
  }
  return true;
};

const ensureWebGl2 = () => {
  if (webState.canvas == null) {
    return false;
  }
  const context = webState.canvas.getContext("webgl2", {
    alpha: true,
    antialias: false,
    depth: false,
    stencil: false,
  });
  if (context == null) {
    return false;
  }
  webState.webgl2.context = context;
  context.viewport(0, 0, webState.width, webState.height);
  return true;
};

const renderWebGpu = () => {
  const device = webState.webgpu.device;
  const context = webState.webgpu.context;
  if (device == null || context == null) {
    return false;
  }
  try {
    const format = typeof webState.webgpu.format === "string"
      ? webState.webgpu.format
      : "bgra8unorm";
    context.configure({
      device,
      format,
      alphaMode: "opaque",
    });
    const [r, g, b, a] = webState.frame.clear;
    const texture = context.getCurrentTexture();
    const view = texture.createView();
    const encoder = device.createCommandEncoder();
    const pass = encoder.beginRenderPass({
      colorAttachments: [{
        view,
        clearValue: { r, g, b, a },
        loadOp: "clear",
        storeOp: "store",
      }],
    });
    pass.end();
    device.queue.submit([encoder.finish()]);
    return true;
  } catch (_) {
    return false;
  }
};

const renderWebGl2 = () => {
  const gl = webState.webgl2.context;
  if (gl == null) {
    return false;
  }
  try {
    gl.viewport(0, 0, webState.width, webState.height);
    const [r, g, b, a] = webState.frame.clear;
    gl.clearColor(r, g, b, a);
    gl.clear(gl.COLOR_BUFFER_BIT);
    return true;
  } catch (_) {
    return false;
  }
};

const run = async () => {
  if (wasmPath == null || wasmPath.length === 0) {
    throw new Error("data-wasm-path is required");
  }
  let output = "";
  const imports = {
    spectest: {
      print_char: (charCode) => {
        output += String.fromCharCode(Number(charCode));
        setOutput(output);
      },
    },
    game_engine_web: {
      prepare_surface: (width, height) => {
        return toInt(ensureCanvas(Number(width), Number(height)));
      },
      surface_kind: () => {
        return webState.backendMode === "webgl2" ? 1 : 0;
      },
      surface_id: () => webState.surfaceId | 0,
      surface_width: (fallbackWidth) => {
        return Math.max(1, webState.width || Number(fallbackWidth) || 1);
      },
      surface_height: (fallbackHeight) => {
        return Math.max(1, webState.height || Number(fallbackHeight) || 1);
      },
      surface_dpr: () => Number(webState.dpr || 1),
      should_close: () => 0,
      gfx_try_initialize: (kind, width, height) => {
        if (!ensureCanvas(Number(width), Number(height))) {
          return 0;
        }
        const backendKind = Number(kind) | 0;
        if (backendKind === 1) {
          if (ensureWebGpu()) {
            webState.backendMode = "webgpu";
            return 1;
          }
          if (ensureWebGl2()) {
            webState.backendMode = "webgl2";
            return 1;
          }
          return 0;
        }
        if (backendKind === 2) {
          const ok = ensureWebGl2();
          if (ok) {
            webState.backendMode = "webgl2";
            return 1;
          }
          return 0;
        }
        return 0;
      },
      gfx_begin: (_kind, clearR, clearG, clearB, clearA) => {
        webState.frame.clear = [
          Number(clearR),
          Number(clearG),
          Number(clearB),
          Number(clearA),
        ];
        webState.frame.drawCalls = 0;
      },
      gfx_draw: (
        _kind,
        drawCalls,
        pipelineId,
        uniformHash,
        blendMode,
        dstImageId,
        shaderId,
        indexOffset,
        regionCount,
        totalIndexCount,
        vertexFloatCount,
        indexCount,
        srcImageCount,
        uniformDwordCount,
        payloadHasTriangle,
        payloadAx,
        payloadAy,
        payloadBx,
        payloadBy,
        payloadCx,
        payloadCy,
        _payloadAu,
        _payloadAv,
        _payloadBu,
        _payloadBv,
        _payloadCu,
        _payloadCv,
        payloadUniformR,
        payloadUniformG,
        payloadUniformB,
        payloadUniformA,
        payloadTextureSeed,
      ) => {
        const n = Number(drawCalls) | 0;
        webState.frame.drawCalls += n <= 0 ? 1 : n;
        webState.frame.commandCount += 1;
        webState.frame.lastPipelineId = Number(pipelineId) | 0;
        webState.frame.lastUniformHash = Number(uniformHash) | 0;
        const safeBlendMode = Number(blendMode) | 0;
        webState.frame.lastBlendMode = safeBlendMode >= 0 && safeBlendMode <= 3 ? safeBlendMode : 1;
        webState.frame.lastDstImageId = Number(dstImageId) | 0;
        webState.frame.lastShaderId = Number(shaderId) | 0;
        webState.frame.lastIndexOffset = Number(indexOffset) | 0;
        webState.frame.lastRegionCount = Number(regionCount) | 0;
        webState.frame.lastTotalIndexCount = Number(totalIndexCount) | 0;
        webState.frame.lastVertexFloatCount = Number(vertexFloatCount) | 0;
        webState.frame.lastIndexCount = Number(indexCount) | 0;
        webState.frame.lastSrcImageCount = Number(srcImageCount) | 0;
        webState.frame.lastUniformDwordCount = Number(uniformDwordCount) | 0;
        webState.frame.payloadHasTriangle = (Number(payloadHasTriangle) | 0) !== 0;
        webState.frame.payloadAx = Number(payloadAx) || 0;
        webState.frame.payloadAy = Number(payloadAy) || 0;
        webState.frame.payloadBx = Number(payloadBx) || 0;
        webState.frame.payloadBy = Number(payloadBy) || 0;
        webState.frame.payloadCx = Number(payloadCx) || 0;
        webState.frame.payloadCy = Number(payloadCy) || 0;
        webState.frame.payloadUniformR = Number(payloadUniformR) || 0;
        webState.frame.payloadUniformG = Number(payloadUniformG) || 0;
        webState.frame.payloadUniformB = Number(payloadUniformB) || 0;
        webState.frame.payloadUniformA = Number(payloadUniformA) || 0;
        webState.frame.payloadTextureSeed = Number(payloadTextureSeed) | 0;
      },
      gfx_end: (_kind, present) => {
        if ((Number(present) | 0) === 0) {
          return;
        }
        ensureCanvas(webState.width, webState.height);
        if (webState.backendMode === "webgpu") {
          if (!renderWebGpu()) {
            renderWebGl2();
          }
        } else {
          renderWebGl2();
        }
        webState.frame.presentedFrames += 1;
        webState.frame.drawCalls = 0;
        webState.frame.commandCount = 0;
      },
      shutdown: () => {
        webState.webgpu.context = null;
        webState.webgpu.device = null;
        webState.webgl2.context = null;
      },
    },
  };
  const response = await fetch(wasmPath);
  if (!response.ok) {
    throw new Error(`failed to fetch wasm: ${response.status}`);
  }
  let instance;
  try {
    ({ instance } = await WebAssembly.instantiateStreaming(response, imports));
  } catch (_) {
    const bytes = await response.arrayBuffer();
    ({ instance } = await WebAssembly.instantiate(bytes, imports));
  }
  const start = instance.exports._start;
  if (typeof start !== "function") {
    throw new Error("wasm export _start not found");
  }
  start();
  setStatus("ok");
  window.__wasmSmoke = {
    status: "ok",
    output,
    backendMode: webState.backendMode,
    presentedFrames: webState.frame.presentedFrames,
    lastRegionCount: webState.frame.lastRegionCount,
    lastTotalIndexCount: webState.frame.lastTotalIndexCount,
    lastVertexFloatCount: webState.frame.lastVertexFloatCount,
    lastIndexCount: webState.frame.lastIndexCount,
    lastSrcImageCount: webState.frame.lastSrcImageCount,
    lastUniformDwordCount: webState.frame.lastUniformDwordCount,
    payloadHasTriangle: webState.frame.payloadHasTriangle,
    payloadAx: webState.frame.payloadAx,
    payloadAy: webState.frame.payloadAy,
    payloadBx: webState.frame.payloadBx,
    payloadBy: webState.frame.payloadBy,
    payloadCx: webState.frame.payloadCx,
    payloadCy: webState.frame.payloadCy,
    payloadUniformR: webState.frame.payloadUniformR,
    payloadUniformG: webState.frame.payloadUniformG,
    payloadUniformB: webState.frame.payloadUniformB,
    payloadUniformA: webState.frame.payloadUniformA,
    payloadTextureSeed: webState.frame.payloadTextureSeed,
  };
};

const boot = async () => {
  setStatus("running");
  try {
    await run();
  } catch (error) {
    const message = error instanceof Error ? error.stack ?? error.message : String(error);
    setStatus("failed");
    setOutput(message);
    window.__wasmSmoke = { status: "failed", output: message };
  }
};

void boot();
