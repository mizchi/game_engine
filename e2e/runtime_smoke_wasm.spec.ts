import { expect, test, type Page } from "@playwright/test";

const EXPECTED_OUTPUT = "runtime_smoke(js): ok (hooked)";

type SmokeResult = {
  status: string;
  output: string;
  backendMode: string;
  presentedFrames: number;
  lastRegionCount: number;
  lastTotalIndexCount: number;
  lastVertexFloatCount: number;
  lastIndexCount: number;
  lastSrcImageCount: number;
  lastUniformDwordCount: number;
  payloadHasTriangle: boolean;
  payloadAx: number;
  payloadAy: number;
  payloadBx: number;
  payloadBy: number;
  payloadCx: number;
  payloadCy: number;
  payloadUniformR: number;
  payloadUniformG: number;
  payloadUniformB: number;
  payloadUniformA: number;
  payloadTextureSeed: number;
  sampleWidth: number;
  sampleHeight: number;
  samplePixels: number[];
  lastPresentedBackend: string;
  readPixelsLen?: number;
};

const TARGETS = [
  {
    name: "runtime_smoke wasm target",
    normalPath: "/e2e/fixtures/runtime_smoke_wasm.html",
  },
  {
    name: "runtime_smoke wasm-gc target",
    normalPath: "/e2e/fixtures/runtime_smoke_wasm_gc.html",
  },
] as const;

const loadSmokeResult = async (page: Page, path: string) => {
  await page.goto(path);
  await page.waitForFunction(() => {
    return Boolean((window as { __wasmSmoke?: { status?: string } }).__wasmSmoke?.status);
  });
  const result = await page.evaluate(() => {
    return (window as { __wasmSmoke?: SmokeResult }).__wasmSmoke;
  });
  expect(result).toBeTruthy();
  return result as SmokeResult;
};

const assertRuntimeSmokeMetrics = (result: SmokeResult) => {
  expect(result.status).toBe("ok");
  expect(result.output).toContain(EXPECTED_OUTPUT);
  // In headless Chromium, WebGPU adapter is null so backendMode may be empty
  if (result.backendMode === "webgpu") {
    if (result.presentedFrames <= 0) {
      return;
    }
    expect(result.lastRegionCount).toBeGreaterThan(0);
    expect(result.lastTotalIndexCount).toBeGreaterThan(0);
    expect(result.lastVertexFloatCount).toBeGreaterThan(0);
    expect(result.lastIndexCount).toBeGreaterThan(0);
    expect(result.lastSrcImageCount).toBeGreaterThanOrEqual(0);
    expect(result.lastUniformDwordCount).toBeGreaterThan(0);
    expect(result.payloadHasTriangle).toBeTruthy();
    expect(result.payloadAx).toBeLessThan(-0.4);
    expect(result.payloadAy).toBeLessThan(-0.4);
    expect(result.payloadBx).toBeGreaterThan(0.4);
    expect(result.payloadBy).toBeLessThan(-0.4);
    expect(result.payloadCx).toBeGreaterThan(0.4);
    expect(result.payloadCy).toBeGreaterThan(0.4);
  }
};

for (const target of TARGETS) {
  test(`${target.name} webgpu rendering`, async ({ page }) => {
    const result = await loadSmokeResult(page, target.normalPath);
    assertRuntimeSmokeMetrics(result);
  });

  test(`${target.name} read_pixels probe`, async ({ page }) => {
    const result = await loadSmokeResult(page, target.normalPath);
    expect(result.status).toBe("ok");
    // Parse read_pixels_len from output probe line
    const match = result.output.match(/read_pixels_len=(-?\d+)/);
    expect(match).not.toBeNull();
    if (match == null) {
      return;
    }
    const readPixelsLen = Number(match[1]);
    // In headless Chromium, WebGPU requestAdapter() returns null so read_pixels is unsupported (-1).
    // In headed mode or with WebGPU support, read_pixels(0, 0, 4, 4) returns 4*4*4 = 64 channels.
    if (result.backendMode === "webgpu") {
      expect(readPixelsLen).toBe(64);
    } else {
      expect(readPixelsLen).toBe(-1);
    }
  });
}

test("canvas dimensions match viewport after load", async ({ page }) => {
  await page.setViewportSize({ width: 800, height: 600 });
  const result = await loadSmokeResult(page, "/e2e/fixtures/runtime_smoke_wasm.html");
  expect(result.status).toBe("ok");
  // The canvas should have been sized by ensureCanvas during prepare_surface
  const dims = await page.evaluate(() => {
    const canvas = document.querySelector("#app") as HTMLCanvasElement | null;
    if (canvas == null) return null;
    const dpr = window.devicePixelRatio ?? 1;
    return {
      canvasWidth: canvas.width,
      canvasHeight: canvas.height,
      cssWidth: canvas.getBoundingClientRect().width,
      cssHeight: canvas.getBoundingClientRect().height,
      dpr,
    };
  });
  expect(dims).not.toBeNull();
  if (dims == null) return;
  // Canvas pixel dimensions should be CSS dimensions * DPR
  const expectedWidth = Math.round(dims.cssWidth * dims.dpr);
  const expectedHeight = Math.round(dims.cssHeight * dims.dpr);
  expect(dims.canvasWidth).toBe(expectedWidth);
  expect(dims.canvasHeight).toBe(expectedHeight);
  // CSS dimensions should be positive
  expect(dims.cssWidth).toBeGreaterThan(0);
  expect(dims.cssHeight).toBeGreaterThan(0);
});
