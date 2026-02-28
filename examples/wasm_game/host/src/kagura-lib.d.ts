declare module "*/kagura-init.js" {
  export function initWebGPU(
    canvasSelector: string,
  ): Promise<{
    canvas: HTMLCanvasElement;
    device: GPUDevice;
    format: GPUTextureFormat;
    context: GPUCanvasContext;
  } | null>;
}

declare module "*/kagura-gfx.js" {
  export function ensureGpuPipeline(
    gpu: Record<string, unknown>,
    device: GPUDevice,
    format: GPUTextureFormat,
  ): boolean;
  export function renderGpu(
    gpu: Record<string, unknown>,
    device: GPUDevice,
    context: GPUCanvasContext,
    clearColor: number[],
    format: GPUTextureFormat,
  ): boolean;
}
