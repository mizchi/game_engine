const statusElement = document.getElementById("status");
const outputElement = document.getElementById("output");
const wasmPath = document.documentElement.getAttribute("data-wasm-path");
const canvasSelector = document.documentElement.getAttribute("data-canvas-selector") ?? "#app";

const SAMPLE_WIDTH = 64;
const SAMPLE_HEIGHT = 64;

const createInitialFrameState = () => ({
  clear: [0, 0, 0, 1],
  drawCommandCount: 0,
  totalVertexCount: 0,
  totalIndexCount: 0,
  // Backwards-compat metrics for e2e tests
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
  audio: null,
  font: { nameBytes: [], fontFiles: new Map() },
  webgpu: {
    context: null,
    device: null,
    format: "bgra8unorm",
    pending: null,
    _pipeline: null,
    _pipelineFormat: "",
    _uniformBGL: null,
    _texBGL: null,
    _defaultTexture: null,
    _defaultTexView: null,
    _defaultSampler: null,
    _drawResourceCache: null,
    commands: [],
    textures: new Map(),
    _currentDraw: null,
    _pendingTexture: null,
  },
  sample: {
    canvas: null,
    context: null,
  },
  frame: createInitialFrameState(),
};

const toInt = (value) => (value ? 1 : 0);

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
  const context = webState.canvas.getContext("webgpu");
  if (context == null) {
    return false;
  }
  webState.webgpu.context = context;
  return true;
};

const ensureWebGpuPipeline = (device, format) => {
  if (webState.webgpu._pipeline != null && webState.webgpu._pipelineFormat === format) {
    return true;
  }
  try {
    const shaderModule = device.createShaderModule({
      code: `
struct Uniforms { color: vec4f }
@group(0) @binding(0) var<uniform> uniforms: Uniforms;
@group(1) @binding(0) var tex: texture_2d<f32>;
@group(1) @binding(1) var tex_sampler: sampler;
struct VertexOutput {
  @builtin(position) position: vec4f,
  @location(0) uv: vec2f,
}
@vertex fn vs_main(@location(0) pos: vec2f, @location(1) uv: vec2f) -> VertexOutput {
  var out: VertexOutput;
  out.position = vec4f(pos, 0.0, 1.0);
  out.uv = uv;
  return out;
}
@fragment fn fs_main(input: VertexOutput) -> @location(0) vec4f {
  let tex_color = textureSample(tex, tex_sampler, input.uv);
  return tex_color * uniforms.color;
}
`,
    });
    const texBGL = device.createBindGroupLayout({
      entries: [
        { binding: 0, visibility: GPUShaderStage.FRAGMENT, texture: { sampleType: "float" } },
        { binding: 1, visibility: GPUShaderStage.FRAGMENT, sampler: {} },
      ],
    });
    const uniformBGL = device.createBindGroupLayout({
      entries: [
        { binding: 0, visibility: GPUShaderStage.FRAGMENT | GPUShaderStage.VERTEX, buffer: { type: "uniform" } },
      ],
    });
    const pipelineLayout = device.createPipelineLayout({ bindGroupLayouts: [uniformBGL, texBGL] });
    const pipeline = device.createRenderPipeline({
      layout: pipelineLayout,
      vertex: {
        module: shaderModule,
        entryPoint: "vs_main",
        buffers: [{
          arrayStride: 16,
          attributes: [
            { shaderLocation: 0, offset: 0, format: "float32x2" },
            { shaderLocation: 1, offset: 8, format: "float32x2" },
          ],
        }],
      },
      fragment: {
        module: shaderModule,
        entryPoint: "fs_main",
        targets: [{
          format,
          blend: {
            color: { srcFactor: "src-alpha", dstFactor: "one-minus-src-alpha", operation: "add" },
            alpha: { srcFactor: "one", dstFactor: "one-minus-src-alpha", operation: "add" },
          },
        }],
      },
      primitive: { topology: "triangle-list", cullMode: "none" },
    });
    // Create default 1x1 white texture
    const defaultTex = device.createTexture({
      size: { width: 1, height: 1 },
      format: "rgba8unorm",
      usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST,
    });
    device.queue.writeTexture(
      { texture: defaultTex },
      new Uint8Array([255, 255, 255, 255]),
      { bytesPerRow: 4 },
      { width: 1, height: 1 },
    );
    webState.webgpu._pipeline = pipeline;
    webState.webgpu._pipelineFormat = format;
    webState.webgpu._uniformBGL = uniformBGL;
    webState.webgpu._texBGL = texBGL;
    webState.webgpu._defaultTexture = defaultTex;
    webState.webgpu._defaultTexView = defaultTex.createView();
    webState.webgpu._defaultSampler = device.createSampler({
      magFilter: "nearest",
      minFilter: "nearest",
    });
    webState.webgpu._drawResourceCache = null;
    return true;
  } catch (_) {
    webState.webgpu._pipeline = null;
    webState.webgpu._pipelineFormat = "";
    webState.webgpu._uniformBGL = null;
    webState.webgpu._texBGL = null;
    webState.webgpu._defaultTexture = null;
    webState.webgpu._defaultTexView = null;
    webState.webgpu._defaultSampler = null;
    webState.webgpu._drawResourceCache = null;
    return false;
  }
};

const releaseBufferEntries = (entries) => {
  if (!Array.isArray(entries)) return;
  for (let i = 0; i < entries.length; i += 1) {
    const entry = entries[i];
    const buffer = entry == null ? null : entry.buffer;
    if (buffer != null && typeof buffer.destroy === "function") {
      try { buffer.destroy(); } catch (_) {}
    }
  }
};

const releaseWebGpuResources = () => {
  const gpu = webState.webgpu;
  if (gpu == null) return;
  const cache = gpu._drawResourceCache;
  if (cache != null) {
    releaseBufferEntries(cache.vertexBuffers);
    releaseBufferEntries(cache.indexBuffers);
    releaseBufferEntries(cache.uniformBuffers);
  }
  const textures = gpu.textures;
  if (textures != null && typeof textures.values === "function") {
    for (const entry of textures.values()) {
      const texture = entry == null ? null : entry.texture;
      if (texture != null && typeof texture.destroy === "function") {
        try { texture.destroy(); } catch (_) {}
      }
    }
  }
  if (textures != null && typeof textures.clear === "function") {
    textures.clear();
  }
  if (gpu._defaultTexture != null && typeof gpu._defaultTexture.destroy === "function") {
    try { gpu._defaultTexture.destroy(); } catch (_) {}
  }
  if (gpu.context != null && typeof gpu.context.unconfigure === "function") {
    try { gpu.context.unconfigure(); } catch (_) {}
  }
  gpu._pipeline = null;
  gpu._pipelineFormat = "";
  gpu._uniformBGL = null;
  gpu._texBGL = null;
  gpu._defaultTexture = null;
  gpu._defaultTexView = null;
  gpu._defaultSampler = null;
  gpu._drawResourceCache = null;
  gpu._pendingTexture = null;
  gpu._currentDraw = null;
  gpu.commands = [];
  gpu.textures = new Map();
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
    context.configure({ device, format, alphaMode: "opaque" });
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
    const drawCommands = webState.webgpu.commands;
    if (webState.webgpu._drawResourceCache == null) {
      webState.webgpu._drawResourceCache = {
        vertexBuffers: [],
        indexBuffers: [],
        uniformBuffers: [],
        uniformBindGroups: [],
        uniformBindBuffers: [],
        textureBindGroups: [],
        textureBindImageIds: [],
        textureBindRevisions: [],
      };
    }
    const cache = webState.webgpu._drawResourceCache;
    const ensureBufferEntry = (slots, slotIndex, minSize, usage) => {
      const requiredSize = Math.max(16, Number(minSize) | 0);
      let entry = slots[slotIndex];
      const currentSize = entry == null ? 0 : (Number(entry.size ?? 0) | 0);
      if (entry == null || currentSize < requiredSize) {
        if (entry != null && entry.buffer != null && typeof entry.buffer.destroy === "function") {
          try { entry.buffer.destroy(); } catch (_) {}
        }
        entry = {
          size: requiredSize,
          buffer: device.createBuffer({ size: requiredSize, usage }),
        };
        slots[slotIndex] = entry;
      }
      return entry;
    };
    for (let drawIndex = 0; drawIndex < drawCommands.length; drawIndex += 1) {
      const cmd = drawCommands[drawIndex];
      if (cmd.vertexData == null || cmd.vertexData.length === 0) continue;
      if (cmd.indices == null || cmd.indices.length === 0) continue;
      const vbEntry = ensureBufferEntry(
        cache.vertexBuffers,
        drawIndex,
        cmd.vertexData.byteLength,
        GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
      );
      device.queue.writeBuffer(vbEntry.buffer, 0, cmd.vertexData);
      const ibEntry = ensureBufferEntry(
        cache.indexBuffers,
        drawIndex,
        cmd.indices.byteLength,
        GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST,
      );
      device.queue.writeBuffer(ibEntry.buffer, 0, cmd.indices);
      const ubEntry = ensureBufferEntry(
        cache.uniformBuffers,
        drawIndex,
        16,
        GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
      );
      device.queue.writeBuffer(ubEntry.buffer, 0, new Float32Array([
        cmd.uniformR, cmd.uniformG, cmd.uniformB, cmd.uniformA,
      ]));
      let uniformBG = cache.uniformBindGroups[drawIndex];
      if (uniformBG == null || cache.uniformBindBuffers[drawIndex] !== ubEntry.buffer) {
        uniformBG = device.createBindGroup({
          layout: webState.webgpu._uniformBGL,
          entries: [{ binding: 0, resource: { buffer: ubEntry.buffer } }],
        });
        cache.uniformBindGroups[drawIndex] = uniformBG;
        cache.uniformBindBuffers[drawIndex] = ubEntry.buffer;
      }
      let texView = webState.webgpu._defaultTexView;
      let texSampler = webState.webgpu._defaultSampler;
      let resolvedImageId = 0;
      let resolvedRevision = -1;
      if (cmd.srcImageId > 0) {
        const texEntry = webState.webgpu.textures.get(cmd.srcImageId);
        if (texEntry != null) {
          texView = texEntry.view;
          texSampler = texEntry.sampler;
          resolvedImageId = Number(cmd.srcImageId) | 0;
          resolvedRevision = Number.isFinite(texEntry.revision)
            ? (texEntry.revision | 0)
            : 0;
        }
      }
      let texBG = cache.textureBindGroups[drawIndex];
      if (
        texBG == null ||
        cache.textureBindImageIds[drawIndex] !== resolvedImageId ||
        cache.textureBindRevisions[drawIndex] !== resolvedRevision
      ) {
        texBG = device.createBindGroup({
          layout: webState.webgpu._texBGL,
          entries: [
            { binding: 0, resource: texView },
            { binding: 1, resource: texSampler },
          ],
        });
        cache.textureBindGroups[drawIndex] = texBG;
        cache.textureBindImageIds[drawIndex] = resolvedImageId;
        cache.textureBindRevisions[drawIndex] = resolvedRevision;
      }
      pass.setPipeline(webState.webgpu._pipeline);
      pass.setBindGroup(0, uniformBG);
      pass.setBindGroup(1, texBG);
      pass.setVertexBuffer(0, vbEntry.buffer);
      pass.setIndexBuffer(ibEntry.buffer, "uint32");
      pass.drawIndexed(cmd.indices.length);
    }
    pass.end();
    device.queue.submit([encoder.finish()]);
    webState.webgpu.commands = [];
    return true;
  } catch (_) {
    return false;
  }
};

const run = async () => {
  if (wasmPath == null || wasmPath.length === 0) {
    throw new Error("data-wasm-path is required");
  }
  webState.backendMode = "";
  releaseWebGpuResources();
  webState.webgpu.context = null;
  webState.webgpu.device = null;
  webState.webgpu.pending = null;
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
      surface_kind: () => 0,
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
        webState.frame.drawCommandCount = 0;
        webState.frame.totalVertexCount = 0;
        webState.frame.totalIndexCount = 0;
      },
      gfx_draw_begin: (vertexCount, indexCount, srcImageId, uniformR, uniformG, uniformB, uniformA) => {
        const vc = Number(vertexCount) | 0;
        const ic = Number(indexCount) | 0;
        webState.webgpu._currentDraw = {
          vertexData: new Float32Array(vc * 4),
          indices: new Uint32Array(ic),
          srcImageId: Number(srcImageId) | 0,
          uniformR: (Number(uniformR) & 0xff) / 255.0,
          uniformG: (Number(uniformG) & 0xff) / 255.0,
          uniformB: (Number(uniformB) & 0xff) / 255.0,
          uniformA: (Number(uniformA) & 0xff) / 255.0,
          _vertexCount: vc,
          _indexCount: ic,
        };
      },
      gfx_draw_vertex: (offset, x, y, u, v) => {
        const draw = webState.webgpu._currentDraw;
        if (draw == null) return;
        const base = (Number(offset) | 0) * 4;
        draw.vertexData[base] = Number(x);
        draw.vertexData[base + 1] = Number(y);
        draw.vertexData[base + 2] = Number(u);
        draw.vertexData[base + 3] = Number(v);
      },
      gfx_draw_index: (offset, value) => {
        const draw = webState.webgpu._currentDraw;
        if (draw == null) return;
        draw.indices[Number(offset) | 0] = Number(value) | 0;
      },
      gfx_draw_end: () => {
        const draw = webState.webgpu._currentDraw;
        if (draw == null) return;
        webState.webgpu._currentDraw = null;
        webState.webgpu.commands.push(draw);
        // Update frame metrics for e2e test diagnostics
        webState.frame.drawCommandCount += 1;
        webState.frame.totalVertexCount += draw._vertexCount;
        webState.frame.totalIndexCount += draw._indexCount;
        // Backwards-compat: extract first command's geometry for e2e payload assertions
        if (webState.frame.drawCommandCount === 1 && draw._vertexCount >= 3) {
          webState.frame.payloadHasTriangle = true;
          webState.frame.payloadAx = draw.vertexData[0];
          webState.frame.payloadAy = draw.vertexData[1];
          webState.frame.payloadBx = draw.vertexData[4];
          webState.frame.payloadBy = draw.vertexData[5];
          webState.frame.payloadCx = draw.vertexData[8];
          webState.frame.payloadCy = draw.vertexData[9];
          webState.frame.payloadUniformR = draw.uniformR;
          webState.frame.payloadUniformG = draw.uniformG;
          webState.frame.payloadUniformB = draw.uniformB;
          webState.frame.payloadUniformA = draw.uniformA;
          webState.frame.payloadTextureSeed = draw.srcImageId;
        }
        // Backwards-compat: populate legacy metric fields
        webState.frame.lastRegionCount = webState.frame.drawCommandCount;
        webState.frame.lastTotalIndexCount = webState.frame.totalIndexCount;
        webState.frame.lastVertexFloatCount = webState.frame.totalVertexCount * 4;
        webState.frame.lastIndexCount = draw._indexCount;
        webState.frame.lastSrcImageCount = draw.srcImageId > 0 ? 1 : 0;
        webState.frame.lastUniformDwordCount = 4;
      },
      gfx_upload_texture_begin: (imageId, width, height) => {
        const w = Math.max(1, Number(width) | 0);
        const h = Math.max(1, Number(height) | 0);
        webState.webgpu._pendingTexture = {
          imageId: Number(imageId) | 0,
          width: w,
          height: h,
          pixels: new Uint8Array(w * h * 4),
        };
      },
      gfx_upload_texture_pixel: (offset, r, g, b, a) => {
        const tex = webState.webgpu._pendingTexture;
        if (tex == null) return;
        const base = (Number(offset) | 0) * 4;
        tex.pixels[base] = Number(r) & 0xff;
        tex.pixels[base + 1] = Number(g) & 0xff;
        tex.pixels[base + 2] = Number(b) & 0xff;
        tex.pixels[base + 3] = Number(a) & 0xff;
      },
      gfx_upload_texture_end: () => {
        const tex = webState.webgpu._pendingTexture;
        webState.webgpu._pendingTexture = null;
        if (tex == null) return;
        const { imageId, width, height, pixels } = tex;
        if (width <= 0 || height <= 0) return;
        const device = webState.webgpu.device;
        if (device == null) return;
        const existing = webState.webgpu.textures.get(imageId);
        if (existing != null && (existing.width !== width || existing.height !== height)) {
          if (existing.texture != null && typeof existing.texture.destroy === "function") {
            existing.texture.destroy();
          }
          webState.webgpu.textures.delete(imageId);
        }
        let entry = webState.webgpu.textures.get(imageId);
        if (entry == null) {
          const nextRevision = existing != null && Number.isFinite(existing.revision)
            ? ((existing.revision | 0) + 1)
            : 1;
          const gpuTex = device.createTexture({
            size: { width, height },
            format: "rgba8unorm",
            usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST,
          });
          const view = gpuTex.createView();
          const sampler = device.createSampler({
            magFilter: "nearest",
            minFilter: "nearest",
            addressModeU: "clamp-to-edge",
            addressModeV: "clamp-to-edge",
          });
          entry = { texture: gpuTex, view, sampler, width, height, revision: nextRevision };
          webState.webgpu.textures.set(imageId, entry);
        } else if (!Number.isFinite(entry.revision)) {
          entry.revision = 1;
        }
        device.queue.writeTexture(
          { texture: entry.texture },
          pixels,
          { bytesPerRow: width * 4 },
          { width, height },
        );
      },
      gfx_end: (_kind, present) => {
        if ((Number(present) | 0) === 0) {
          return;
        }
        ensureCanvas(webState.width, webState.height);
        let renderedBackend = "none";
        if (renderWebGpu()) {
          renderedBackend = "webgpu";
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
        webState.frame.drawCommandCount = 0;
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
        releaseWebGpuResources();
        webState.webgpu.context = null;
        webState.webgpu.device = null;
        webState.webgpu.pending = null;
        webState.sample.canvas = null;
        webState.sample.context = null;
      },
      load_font_name_len: (len) => {
        webState.font.nameBytes = new Array(Number(len));
      },
      load_font_name_byte: (index, byteVal) => {
        webState.font.nameBytes[Number(index)] = Number(byteVal) & 0xff;
      },
      load_font_data_begin: () => {
        const nameBytes = new Uint8Array(webState.font.nameBytes);
        const name = new TextDecoder().decode(nameBytes);
        const data = webState.font.fontFiles.get(name);
        if (data == null) {
          webState.font._currentData = null;
          return 0;
        }
        webState.font._currentData = data;
        return data.length;
      },
      load_font_data_byte: (offset) => {
        const data = webState.font._currentData;
        if (data == null) return 0;
        return data[Number(offset)] ?? 0;
      },
      audio_try_initialize: (sampleRate, channels) => {
        try {
          const AC = globalThis.AudioContext || globalThis.webkitAudioContext;
          if (!AC) return 0;
          const ctx = new AC({ sampleRate: Number(sampleRate) });
          const ch = Number(channels) || 2;
          const bufSize = 4096;
          const ringSize = bufSize * 8;
          const ring = new Float32Array(ringSize * ch);
          let writePos = 0;
          let readPos = 0;
          const node = ctx.createScriptProcessor(bufSize, 0, ch);
          node.onaudioprocess = (e) => {
            const out = e.outputBuffer;
            const frames = out.length;
            for (let c = 0; c < ch; c++) {
              const chData = out.getChannelData(c);
              for (let i = 0; i < frames; i++) {
                const idx = ((readPos + i) % ringSize) * ch + c;
                chData[i] = ring[idx];
              }
            }
            readPos = (readPos + frames) % ringSize;
          };
          node.connect(ctx.destination);
          webState.audio = { ctx, node, ring, ringSize, writePos, readPos: 0, channels: ch, _frameIdx: 0 };
          return 1;
        } catch (_) {
          return 0;
        }
      },
      audio_write_frame: (channel, value) => {
        const a = webState.audio;
        if (!a) return;
        const ch = Number(channel) | 0;
        const idx = ((a.writePos + a._frameIdx) % a.ringSize) * a.channels + ch;
        a.ring[idx] = Number(value);
        if (ch === a.channels - 1) {
          a._frameIdx++;
        }
      },
      audio_write_end: (frames) => {
        const a = webState.audio;
        if (!a) return 0;
        const f = Number(frames) | 0;
        a.writePos = (a.writePos + f) % a.ringSize;
        a._frameIdx = 0;
        return f;
      },
      audio_suspend: () => {
        const a = webState.audio;
        if (a && a.ctx) a.ctx.suspend();
      },
      audio_resume: () => {
        const a = webState.audio;
        if (a && a.ctx) a.ctx.resume();
      },
      audio_close: () => {
        const a = webState.audio;
        if (a) {
          if (a.node) { a.node.disconnect(); }
          if (a.ctx) { a.ctx.close(); }
          webState.audio = null;
        }
      },
      audio_output_latency: () => {
        const a = webState.audio;
        if (a && a.ctx) return a.ctx.outputLatency || 0;
        return 0;
      },
    },
  };
  // Pre-initialize WebGPU device before WASM runs so gfx_try_initialize succeeds synchronously
  const nav = typeof navigator === "undefined" ? null : navigator;
  if (nav != null && nav.gpu != null) {
    try {
      const adapter = await nav.gpu.requestAdapter();
      if (adapter != null) {
        const device = await adapter.requestDevice();
        if (device != null) {
          const format = typeof nav.gpu.getPreferredCanvasFormat === "function"
            ? nav.gpu.getPreferredCanvasFormat()
            : "bgra8unorm";
          webState.webgpu.device = device;
          webState.webgpu.format = format;
        }
      }
    } catch (_) {
      // WebGPU not available
    }
  }

  // Pre-fetch font files for font smoke test
  const fontPaths = [
    ".mooncakes/mizchi/font/fixtures/NotoSans-subset.otf",
    ".mooncakes/mizchi/font/fixtures/NotoSansMono-Regular.ttf",
    "fixtures/fonts/NotoSansJP-subset.otf",
  ];
  for (const fontPath of fontPaths) {
    try {
      const fontResp = await fetch("/" + fontPath);
      if (fontResp.ok) {
        const buf = await fontResp.arrayBuffer();
        webState.font.fontFiles.set(fontPath, new Uint8Array(buf));
      }
    } catch (_) {
      // Font fetch failed — font smoke will report load=false
    }
  }

  const response = await fetch(wasmPath);
  if (!response.ok) {
    throw new Error(`failed to fetch wasm: ${response.status}`);
  }
  let instance;
  try {
    ({ instance } = await WebAssembly.instantiateStreaming(response.clone(), imports));
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
