import { initWebGPU } from "../../../../lib/web/kagura-init.js";
import {
  ensureGpuPipeline,
  renderGpu,
} from "../../../../lib/web/kagura-gfx.js";
import { createInputCollector } from "./input-collector";
import {
  serializeInput,
  deserializeDrawCommands,
  inputByteSize,
} from "./host-protocol";

interface GameExports {
  kagura_init: () => number;
  kagura_alloc: (size: number) => number;
  kagura_update: (ptr: number, len: number) => void;
  kagura_draw: () => number;
  memory: WebAssembly.Memory;
  _start?: () => void;
}

async function loadWasm(url: string): Promise<GameExports> {
  const response = await fetch(url);
  const { instance } = await WebAssembly.instantiateStreaming(response, {});
  const exports = instance.exports as unknown as GameExports;
  // MoonBit WASM exports _start for module initialization
  if (exports._start) {
    exports._start();
  }
  return exports;
}

function readGameConfig(memory: WebAssembly.Memory, ptr: number) {
  const dv = new DataView(memory.buffer);
  const width = dv.getInt32(ptr, true);
  const height = dv.getInt32(ptr + 4, true);
  const titleLen = dv.getInt32(ptr + 8, true);
  const titleBytes = new Uint8Array(memory.buffer, ptr + 12, titleLen);
  const title = new TextDecoder().decode(titleBytes);
  return { width, height, title };
}

async function main() {
  const gpuResult = await initWebGPU("#app");
  if (!gpuResult) {
    document.body.textContent = "WebGPU not supported";
    return;
  }
  const { canvas, device, format, context } = gpuResult;

  // GPU state object (matches kagura-gfx.js expectations)
  const gpu: Record<string, unknown> = {
    _pipeline: null,
    _pipelineFormat: "",
    _uniformBGL: null,
    _texBGL: null,
    _defaultTexture: null,
    _defaultTexView: null,
    _defaultSampler: null,
    _drawResourceCache: null,
    _pendingTexture: null,
    _currentDraw: null,
    commands: [] as unknown[],
    textures: new Map(),
  };

  ensureGpuPipeline(gpu, device, format);

  let game = await loadWasm("/game.wasm");

  // Initialize game
  const configPtr = game.kagura_init();
  const config = readGameConfig(game.memory, configPtr);
  canvas.width = config.width;
  canvas.height = config.height;
  document.title = config.title;

  const input = createInputCollector(canvas);

  function frame() {
    const snap = input.snapshot();

    // Allocate space for input in WASM memory
    const inputSize = inputByteSize(snap);
    const inputPtr = game.kagura_alloc(inputSize);

    // Write input to WASM memory
    const bytesWritten = serializeInput(game.memory, inputPtr, snap);

    // Update game state
    game.kagura_update(inputPtr, bytesWritten);

    // Get draw commands
    const drawPtr = game.kagura_draw();
    const commands = deserializeDrawCommands(game.memory, drawPtr);

    // Convert to kagura-gfx format and render
    gpu.commands = commands;
    renderGpu(gpu, device, context, [0, 0, 0, 1], format);

    requestAnimationFrame(frame);
  }

  requestAnimationFrame(frame);

  // HMR: reload WASM on changes
  if (import.meta.hot) {
    import.meta.hot.on("wasm-update", async () => {
      console.log("[HMR] Reloading game.wasm...");
      try {
        game = await loadWasm("/game.wasm?t=" + Date.now());
        const newConfigPtr = game.kagura_init();
        const newConfig = readGameConfig(game.memory, newConfigPtr);
        canvas.width = newConfig.width;
        canvas.height = newConfig.height;
        console.log("[HMR] Game reloaded:", newConfig.title);
      } catch (e) {
        console.error("[HMR] Failed to reload:", e);
      }
    });
  }
}

main().catch(console.error);
