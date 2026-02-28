// Shared GFX/WebGPU backend for kagura — used by both JS-target (via globalThis.__kaguraGfx)
// and WASM-target (via ES module import)

const SHADER_CODE = `
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
}`;

/**
 * Ensure the GPU render pipeline, bind group layouts, and default texture are created.
 * Returns true if pipeline is ready.
 */
export function ensureGpuPipeline(gpu, device, format) {
  if (gpu._pipeline != null && gpu._pipelineFormat === format) {
    return true;
  }
  try {
    const shaderModule = device.createShaderModule({ code: SHADER_CODE });
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
    gpu._pipeline = pipeline;
    gpu._pipelineFormat = format;
    gpu._uniformBGL = uniformBGL;
    gpu._texBGL = texBGL;
    gpu._defaultTexture = defaultTex;
    gpu._defaultTexView = defaultTex.createView();
    gpu._defaultSampler = device.createSampler({ magFilter: "nearest", minFilter: "nearest" });
    gpu._drawResourceCache = null;
    return true;
  } catch (_) {
    gpu._pipeline = null;
    gpu._pipelineFormat = "";
    gpu._uniformBGL = null;
    gpu._texBGL = null;
    gpu._defaultTexture = null;
    gpu._defaultTexView = null;
    gpu._defaultSampler = null;
    gpu._drawResourceCache = null;
    return false;
  }
}

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

/**
 * Release all GPU resources (buffers, textures, pipeline, etc.) and reset state.
 */
export function releaseGpuResources(gpu) {
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
}

/**
 * Finalize a pending texture upload: create/update GPU texture from staged pixel data.
 */
export function finalizeTextureUpload(gpu) {
  if (gpu == null || gpu._pendingTexture == null || gpu.device == null) return;
  const { imageId, width, height, pixels } = gpu._pendingTexture;
  gpu._pendingTexture = null;
  if (width <= 0 || height <= 0) return;
  if (gpu.textures == null) gpu.textures = new Map();
  const existing = gpu.textures.get(imageId);
  if (existing != null && (existing.width !== width || existing.height !== height)) {
    if (existing.texture != null && typeof existing.texture.destroy === "function") {
      existing.texture.destroy();
    }
    gpu.textures.delete(imageId);
  }
  let entry = gpu.textures.get(imageId);
  if (entry == null) {
    const nextRevision = existing != null && Number.isFinite(existing.revision)
      ? ((existing.revision | 0) + 1)
      : 1;
    const texture = gpu.device.createTexture({
      size: { width, height },
      format: "rgba8unorm",
      usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST,
    });
    const view = texture.createView();
    const sampler = gpu.device.createSampler({
      magFilter: "nearest",
      minFilter: "nearest",
      addressModeU: "clamp-to-edge",
      addressModeV: "clamp-to-edge",
    });
    entry = { texture, view, sampler, width, height, revision: nextRevision };
    gpu.textures.set(imageId, entry);
  } else if (!Number.isFinite(entry.revision)) {
    entry.revision = 1;
  }
  gpu.device.queue.writeTexture(
    { texture: entry.texture },
    pixels,
    { bytesPerRow: width * 4 },
    { width, height },
  );
}

/**
 * Render all queued draw commands using WebGPU.
 * Returns true if rendering succeeded.
 */
export function renderGpu(gpu, device, context, clearColor, format) {
  if (device == null || context == null) return false;
  try {
    const safeFormat = typeof format === "string" && format.length > 0 ? format : "bgra8unorm";
    if (!ensureGpuPipeline(gpu, device, safeFormat)) return false;
    context.configure({ device, format: safeFormat, alphaMode: "opaque" });
    const [r, g, b, a] = clearColor;
    const texture = context.getCurrentTexture();
    const view = texture.createView();
    const encoder = device.createCommandEncoder();
    const pass = encoder.beginRenderPass({
      colorAttachments: [{ view, clearValue: { r, g, b, a }, loadOp: "clear", storeOp: "store" }],
    });
    const drawCommands = Array.isArray(gpu.commands) ? gpu.commands : [];
    if (gpu._drawResourceCache == null) {
      gpu._drawResourceCache = {
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
    const cache = gpu._drawResourceCache;
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
        cache.vertexBuffers, drawIndex, cmd.vertexData.byteLength,
        GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
      );
      device.queue.writeBuffer(vbEntry.buffer, 0, cmd.vertexData);
      const ibEntry = ensureBufferEntry(
        cache.indexBuffers, drawIndex, cmd.indices.byteLength,
        GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST,
      );
      device.queue.writeBuffer(ibEntry.buffer, 0, cmd.indices);
      const ubEntry = ensureBufferEntry(
        cache.uniformBuffers, drawIndex, 16,
        GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
      );
      device.queue.writeBuffer(ubEntry.buffer, 0, new Float32Array([
        cmd.uniformR, cmd.uniformG, cmd.uniformB, cmd.uniformA,
      ]));
      let uniformBG = cache.uniformBindGroups[drawIndex];
      if (uniformBG == null || cache.uniformBindBuffers[drawIndex] !== ubEntry.buffer) {
        uniformBG = device.createBindGroup({
          layout: gpu._uniformBGL,
          entries: [{ binding: 0, resource: { buffer: ubEntry.buffer } }],
        });
        cache.uniformBindGroups[drawIndex] = uniformBG;
        cache.uniformBindBuffers[drawIndex] = ubEntry.buffer;
      }
      let texView = gpu._defaultTexView;
      let texSampler = gpu._defaultSampler;
      let resolvedImageId = 0;
      let resolvedRevision = -1;
      if (gpu.textures != null && cmd.srcImageId > 0) {
        const texEntry = gpu.textures.get(cmd.srcImageId);
        if (texEntry != null) {
          texView = texEntry.view;
          texSampler = texEntry.sampler;
          resolvedImageId = cmd.srcImageId | 0;
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
          layout: gpu._texBGL,
          entries: [
            { binding: 0, resource: texView },
            { binding: 1, resource: texSampler },
          ],
        });
        cache.textureBindGroups[drawIndex] = texBG;
        cache.textureBindImageIds[drawIndex] = resolvedImageId;
        cache.textureBindRevisions[drawIndex] = resolvedRevision;
      }
      pass.setPipeline(gpu._pipeline);
      pass.setBindGroup(0, uniformBG);
      pass.setBindGroup(1, texBG);
      pass.setVertexBuffer(0, vbEntry.buffer);
      pass.setIndexBuffer(ibEntry.buffer, "uint32");
      pass.drawIndexed(cmd.indices.length);
    }
    pass.end();
    device.queue.submit([encoder.finish()]);
    gpu.commands = [];
    return true;
  } catch (_) {
    return false;
  }
}

/**
 * Install GFX helpers on globalThis for use from MoonBit extern "js" inline code.
 */
export function installGfxHelpers() {
  globalThis.__kaguraGfx = {
    ensurePipeline: ensureGpuPipeline,
    render: renderGpu,
    release: releaseGpuResources,
    finalizeTexture: finalizeTextureUpload,
  };
}
