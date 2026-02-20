const statusElement = document.getElementById("status");
const outputElement = document.getElementById("output");
const wasmPath = document.documentElement.getAttribute("data-wasm-path");
const canvasSelector = document.documentElement.getAttribute("data-canvas-selector") ?? "#app";
const forceWebGl = document.documentElement.getAttribute("data-force-webgl") === "1";

const SAMPLE_WIDTH = 64;
const SAMPLE_HEIGHT = 64;

const createInitialFrameState = () => ({
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
  sampleWidth: 0,
  sampleHeight: 0,
  samplePixels: [],
  lastPresentedBackend: "none",
});

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
    pipeline: null,
    pipelineFormat: "",
    vertexBuffer: null,
    uniformBuffer: null,
    bindGroup: null,
  },
  webgl2: {
    context: null,
    program: null,
    vertexBuffer: null,
    positionLocation: -1,
    colorLocation: null,
  },
  sample: {
    canvas: null,
    context: null,
  },
  frame: createInitialFrameState(),
};

const toInt = (value) => (value ? 1 : 0);

const clampUnit = (value) => {
  if (!Number.isFinite(value)) {
    return 0;
  }
  if (value < 0) {
    return 0;
  }
  if (value > 1) {
    return 1;
  }
  return value;
};

const normalizedTriangleVertices = () => {
  if (!webState.frame.payloadHasTriangle) {
    return new Float32Array([0.0, 0.6, -0.6, -0.6, 0.6, -0.6]);
  }
  return new Float32Array([
    Number(webState.frame.payloadAx) || 0,
    Number(webState.frame.payloadAy) || 0,
    Number(webState.frame.payloadBx) || 0,
    Number(webState.frame.payloadBy) || 0,
    Number(webState.frame.payloadCx) || 0,
    Number(webState.frame.payloadCy) || 0,
  ]);
};

const normalizedTriangleColor = () => {
  let r = clampUnit(Number(webState.frame.payloadUniformR));
  let g = clampUnit(Number(webState.frame.payloadUniformG));
  let b = clampUnit(Number(webState.frame.payloadUniformB));
  let a = clampUnit(Number(webState.frame.payloadUniformA));
  if (r + g + b < 0.12) {
    const seed = Math.abs(Number(webState.frame.payloadTextureSeed) | 0);
    r = ((seed >> 0) & 0xff) / 255;
    g = ((seed >> 8) & 0xff) / 255;
    b = ((seed >> 16) & 0xff) / 255;
    if (r + g + b < 0.3) {
      r = 0.92;
      g = 0.26;
      b = 0.18;
    }
  }
  if (a < 0.2) {
    a = 1;
  }
  return [r, g, b, a];
};

const captureCanvasSample = () => {
  const sourceCanvas = webState.canvas;
  const doc = typeof document === "undefined" ? null : document;
  if (sourceCanvas == null || doc == null) {
    return null;
  }
  if (webState.sample.canvas == null) {
    const sampleCanvas = doc.createElement("canvas");
    sampleCanvas.width = SAMPLE_WIDTH;
    sampleCanvas.height = SAMPLE_HEIGHT;
    webState.sample.canvas = sampleCanvas;
    webState.sample.context = sampleCanvas.getContext("2d", { willReadFrequently: true });
  }
  const sampleCanvas = webState.sample.canvas;
  const sampleContext = webState.sample.context;
  if (sampleCanvas == null || sampleContext == null) {
    return null;
  }
  try {
    sampleContext.clearRect(0, 0, SAMPLE_WIDTH, SAMPLE_HEIGHT);
    sampleContext.drawImage(sourceCanvas, 0, 0, SAMPLE_WIDTH, SAMPLE_HEIGHT);
    const imageData = sampleContext.getImageData(0, 0, SAMPLE_WIDTH, SAMPLE_HEIGHT);
    const out = new Uint8Array(imageData.data.length);
    out.set(imageData.data);
    return out;
  } catch (_) {
    return null;
  }
};

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
  // Start adapter/device request if not already started, but do NOT lock the
  // canvas to WebGPU until the device is actually ready.  Otherwise the canvas
  // context type is set to "webgpu" and ensureWebGl2 can no longer create a
  // WebGL2 context for fallback.
  if (webState.webgpu.device == null) {
    if (webState.webgpu.pending == null) {
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
    return false;
  }
  // Device is ready — now safe to lock the canvas to WebGPU
  const context = webState.canvas.getContext("webgpu");
  if (context == null) {
    return false;
  }
  webState.webgpu.context = context;
  return true;
};

const ensureWebGpuPipeline = (device, format) => {
  if (
    webState.webgpu.pipeline != null &&
    webState.webgpu.pipelineFormat === format &&
    webState.webgpu.vertexBuffer != null &&
    webState.webgpu.uniformBuffer != null &&
    webState.webgpu.bindGroup != null
  ) {
    return true;
  }
  try {
    const shaderModule = device.createShaderModule({
      code: `
struct ColorUniform {
  value: vec4f,
}

@group(0) @binding(0) var<uniform> color_uniform: ColorUniform;

struct VertexOutput {
  @builtin(position) position: vec4f,
}

@vertex
fn vs_main(@location(0) position: vec2f) -> VertexOutput {
  var out: VertexOutput;
  out.position = vec4f(position, 0.0, 1.0);
  return out;
}

@fragment
fn fs_main() -> @location(0) vec4f {
  return color_uniform.value;
}
`,
    });
    const pipeline = device.createRenderPipeline({
      layout: "auto",
      vertex: {
        module: shaderModule,
        entryPoint: "vs_main",
        buffers: [{
          arrayStride: 8,
          attributes: [{
            shaderLocation: 0,
            offset: 0,
            format: "float32x2",
          }],
        }],
      },
      fragment: {
        module: shaderModule,
        entryPoint: "fs_main",
        targets: [{ format }],
      },
      primitive: {
        topology: "triangle-list",
      },
    });
    const vertexBuffer = device.createBuffer({
      size: 6 * Float32Array.BYTES_PER_ELEMENT,
      usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
    });
    const uniformBuffer = device.createBuffer({
      size: 4 * Float32Array.BYTES_PER_ELEMENT,
      usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });
    const bindGroup = device.createBindGroup({
      layout: pipeline.getBindGroupLayout(0),
      entries: [{
        binding: 0,
        resource: { buffer: uniformBuffer },
      }],
    });
    webState.webgpu.pipeline = pipeline;
    webState.webgpu.pipelineFormat = format;
    webState.webgpu.vertexBuffer = vertexBuffer;
    webState.webgpu.uniformBuffer = uniformBuffer;
    webState.webgpu.bindGroup = bindGroup;
    return true;
  } catch (_) {
    webState.webgpu.pipeline = null;
    webState.webgpu.pipelineFormat = "";
    webState.webgpu.vertexBuffer = null;
    webState.webgpu.uniformBuffer = null;
    webState.webgpu.bindGroup = null;
    return false;
  }
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
    preserveDrawingBuffer: true,
  });
  if (context == null) {
    return false;
  }
  webState.webgl2.context = context;
  context.viewport(0, 0, webState.width, webState.height);
  return true;
};

const compileWebGlShader = (gl, type, source) => {
  const shader = gl.createShader(type);
  if (shader == null) {
    return null;
  }
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  const ok = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
  if (!ok) {
    gl.deleteShader(shader);
    return null;
  }
  return shader;
};

const ensureWebGl2Program = (gl) => {
  if (
    webState.webgl2.program != null &&
    webState.webgl2.vertexBuffer != null &&
    webState.webgl2.positionLocation >= 0 &&
    webState.webgl2.colorLocation != null
  ) {
    return true;
  }
  const vertexShader = compileWebGlShader(
    gl,
    gl.VERTEX_SHADER,
    `#version 300 es
in vec2 a_position;
void main() {
  gl_Position = vec4(a_position, 0.0, 1.0);
}
`,
  );
  const fragmentShader = compileWebGlShader(
    gl,
    gl.FRAGMENT_SHADER,
    `#version 300 es
precision highp float;
uniform vec4 u_color;
out vec4 out_color;
void main() {
  out_color = u_color;
}
`,
  );
  if (vertexShader == null || fragmentShader == null) {
    if (vertexShader != null) {
      gl.deleteShader(vertexShader);
    }
    if (fragmentShader != null) {
      gl.deleteShader(fragmentShader);
    }
    return false;
  }
  const program = gl.createProgram();
  if (program == null) {
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);
    return false;
  }
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  gl.deleteShader(vertexShader);
  gl.deleteShader(fragmentShader);
  const linked = gl.getProgramParameter(program, gl.LINK_STATUS);
  if (!linked) {
    gl.deleteProgram(program);
    return false;
  }
  const positionLocation = gl.getAttribLocation(program, "a_position");
  const colorLocation = gl.getUniformLocation(program, "u_color");
  const vertexBuffer = gl.createBuffer();
  if (positionLocation < 0 || colorLocation == null || vertexBuffer == null) {
    gl.deleteProgram(program);
    if (vertexBuffer != null) {
      gl.deleteBuffer(vertexBuffer);
    }
    return false;
  }
  webState.webgl2.program = program;
  webState.webgl2.positionLocation = positionLocation;
  webState.webgl2.colorLocation = colorLocation;
  webState.webgl2.vertexBuffer = vertexBuffer;
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
    if (!ensureWebGpuPipeline(device, format)) {
      return false;
    }
    const vertices = normalizedTriangleVertices();
    const [colorR, colorG, colorB, colorA] = normalizedTriangleColor();
    device.queue.writeBuffer(webState.webgpu.vertexBuffer, 0, vertices);
    device.queue.writeBuffer(
      webState.webgpu.uniformBuffer,
      0,
      new Float32Array([colorR, colorG, colorB, colorA]),
    );
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
    if (webState.frame.payloadHasTriangle) {
      pass.setPipeline(webState.webgpu.pipeline);
      pass.setBindGroup(0, webState.webgpu.bindGroup);
      pass.setVertexBuffer(0, webState.webgpu.vertexBuffer);
      pass.draw(3, 1, 0, 0);
    }
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
    if (!webState.frame.payloadHasTriangle) {
      return true;
    }
    if (!ensureWebGl2Program(gl)) {
      return false;
    }
    const [colorR, colorG, colorB, colorA] = normalizedTriangleColor();
    const vertices = normalizedTriangleVertices();
    gl.useProgram(webState.webgl2.program);
    gl.bindBuffer(gl.ARRAY_BUFFER, webState.webgl2.vertexBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.DYNAMIC_DRAW);
    gl.enableVertexAttribArray(webState.webgl2.positionLocation);
    gl.vertexAttribPointer(
      webState.webgl2.positionLocation,
      2,
      gl.FLOAT,
      false,
      0,
      0,
    );
    gl.uniform4f(webState.webgl2.colorLocation, colorR, colorG, colorB, colorA);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    return true;
  } catch (_) {
    return false;
  }
};

const run = async () => {
  if (wasmPath == null || wasmPath.length === 0) {
    throw new Error("data-wasm-path is required");
  }
  webState.backendMode = forceWebGl ? "webgl2" : "webgpu";
  webState.webgpu.context = null;
  webState.webgpu.device = null;
  webState.webgpu.pending = null;
  webState.webgpu.pipeline = null;
  webState.webgpu.pipelineFormat = "";
  webState.webgpu.vertexBuffer = null;
  webState.webgpu.uniformBuffer = null;
  webState.webgpu.bindGroup = null;
  webState.webgl2.context = null;
  webState.webgl2.program = null;
  webState.webgl2.vertexBuffer = null;
  webState.webgl2.positionLocation = -1;
  webState.webgl2.colorLocation = null;
  webState.sample.canvas = null;
  webState.sample.context = null;
  webState.frame = createInitialFrameState();
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
          if (!forceWebGl && ensureWebGpu()) {
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
        let renderedBackend = "none";
        if (webState.backendMode === "webgpu") {
          if (renderWebGpu()) {
            renderedBackend = "webgpu";
          } else if (ensureWebGl2() && renderWebGl2()) {
            renderedBackend = "webgl2-fallback";
          }
        } else if (renderWebGl2()) {
          renderedBackend = "webgl2";
        }
        const samplePixels = captureCanvasSample();
        if (samplePixels != null) {
          webState.frame.sampleWidth = SAMPLE_WIDTH;
          webState.frame.sampleHeight = SAMPLE_HEIGHT;
          webState.frame.samplePixels = Array.from(samplePixels);
        } else {
          webState.frame.sampleWidth = 0;
          webState.frame.sampleHeight = 0;
          webState.frame.samplePixels = [];
        }
        webState.frame.lastPresentedBackend = renderedBackend;
        webState.frame.presentedFrames += 1;
        webState.frame.drawCalls = 0;
        webState.frame.commandCount = 0;
      },
      gfx_read_pixels_begin: (_kind, x, y, w, h) => {
        const sx = Number(x) | 0;
        const sy = Number(y) | 0;
        const sw = Number(w) | 0;
        const sh = Number(h) | 0;
        if (sw <= 0 || sh <= 0 || webState.canvas == null) {
          webState._readPixelsBuffer = null;
          return 0;
        }
        try {
          const doc = typeof document === "undefined" ? null : document;
          if (doc == null) {
            webState._readPixelsBuffer = null;
            return 0;
          }
          if (webState._readPixelsCanvas == null) {
            webState._readPixelsCanvas = doc.createElement("canvas");
            webState._readPixelsContext = webState._readPixelsCanvas.getContext("2d", { willReadFrequently: true });
          }
          webState._readPixelsCanvas.width = sw;
          webState._readPixelsCanvas.height = sh;
          webState._readPixelsContext.clearRect(0, 0, sw, sh);
          webState._readPixelsContext.drawImage(webState.canvas, sx, sy, sw, sh, 0, 0, sw, sh);
          const imageData = webState._readPixelsContext.getImageData(0, 0, sw, sh);
          webState._readPixelsBuffer = new Uint8Array(imageData.data.length);
          webState._readPixelsBuffer.set(imageData.data);
          return sw * sh;
        } catch (_) {
          webState._readPixelsBuffer = null;
          return 0;
        }
      },
      gfx_read_pixels_channel: (offset) => {
        const buf = webState._readPixelsBuffer;
        if (buf == null) {
          return 0;
        }
        const i = Number(offset) | 0;
        if (i < 0 || i >= buf.length) {
          return 0;
        }
        return buf[i];
      },
      gfx_read_pixels_end: () => {
        webState._readPixelsBuffer = null;
      },
      shutdown: () => {
        webState.webgpu.context = null;
        webState.webgpu.device = null;
        webState.webgpu.pipeline = null;
        webState.webgpu.pipelineFormat = "";
        webState.webgpu.vertexBuffer = null;
        webState.webgpu.uniformBuffer = null;
        webState.webgpu.bindGroup = null;
        webState.webgl2.context = null;
        webState.webgl2.program = null;
        webState.webgl2.vertexBuffer = null;
        webState.webgl2.positionLocation = -1;
        webState.webgl2.colorLocation = null;
        webState.sample.canvas = null;
        webState.sample.context = null;
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
  await new Promise((resolve) => setTimeout(resolve, 0));
  const finalSample = captureCanvasSample();
  if (finalSample != null) {
    webState.frame.sampleWidth = SAMPLE_WIDTH;
    webState.frame.sampleHeight = SAMPLE_HEIGHT;
    webState.frame.samplePixels = Array.from(finalSample);
  }
  setStatus("ok");
  window.__wasmSmoke = {
    status: "ok",
    output,
    forceWebGl,
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
    sampleWidth: webState.frame.sampleWidth,
    sampleHeight: webState.frame.sampleHeight,
    samplePixels: webState.frame.samplePixels,
    lastPresentedBackend: webState.frame.lastPresentedBackend,
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
