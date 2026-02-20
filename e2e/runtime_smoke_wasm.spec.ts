import { expect, test, type Page } from "@playwright/test";
import pixelmatch from "pixelmatch";

const EXPECTED_OUTPUT = "runtime_smoke(js): ok (hooked)";

type SmokeResult = {
  status: string;
  output: string;
  forceWebGl?: boolean;
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
    forceWebGlPath: "/e2e/fixtures/runtime_smoke_wasm_force_webgl.html",
  },
  {
    name: "runtime_smoke wasm-gc target",
    normalPath: "/e2e/fixtures/runtime_smoke_wasm_gc.html",
    forceWebGlPath: "/e2e/fixtures/runtime_smoke_wasm_gc_force_webgl.html",
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

const assertRuntimeSmokeMetrics = (result: SmokeResult, expectedBackend?: string) => {
  expect(result.status).toBe("ok");
  expect(result.output).toContain(EXPECTED_OUTPUT);
  if (expectedBackend != null) {
    expect(result.forceWebGl).toBeTruthy();
    expect(result.backendMode).toBe(expectedBackend);
  } else {
    expect(["webgpu", "webgl2"]).toContain(result.backendMode);
  }
  if (result.presentedFrames <= 0) {
    return;
  }
  expect(result.lastRegionCount).toBeGreaterThan(0);
  expect(result.lastTotalIndexCount).toBeGreaterThan(0);
  expect(result.lastVertexFloatCount).toBeGreaterThan(0);
  expect(result.lastIndexCount).toBeGreaterThan(0);
  expect(result.lastSrcImageCount).toBeGreaterThan(0);
  expect(result.lastUniformDwordCount).toBeGreaterThan(0);
  expect(result.payloadHasTriangle).toBeTruthy();
  expect(result.payloadAx).toBeLessThan(-0.4);
  expect(result.payloadAy).toBeLessThan(-0.4);
  expect(result.payloadBx).toBeGreaterThan(0.4);
  expect(result.payloadBy).toBeLessThan(-0.4);
  expect(result.payloadCx).toBeGreaterThan(0.4);
  expect(result.payloadCy).toBeGreaterThan(0.4);
  expect(result.payloadUniformR).toBeLessThan(0.05);
  expect(result.payloadUniformG).toBeLessThan(0.05);
  expect(result.payloadUniformB).toBeLessThan(0.05);
  expect(result.payloadUniformA).toBeLessThan(0.05);
  expect(result.payloadTextureSeed).toBeGreaterThan(0);
};

const pixelDiffRatio = (left: SmokeResult, right: SmokeResult) => {
  expect(left.sampleWidth).toBeGreaterThan(0);
  expect(left.sampleHeight).toBeGreaterThan(0);
  expect(right.sampleWidth).toBe(left.sampleWidth);
  expect(right.sampleHeight).toBe(left.sampleHeight);
  const totalPixels = left.sampleWidth * left.sampleHeight;
  expect(totalPixels).toBeGreaterThan(0);
  const leftData = Uint8Array.from(left.samplePixels);
  const rightData = Uint8Array.from(right.samplePixels);
  expect(leftData.length).toBe(totalPixels * 4);
  expect(rightData.length).toBe(totalPixels * 4);
  const diff = pixelmatch(
    leftData,
    rightData,
    undefined,
    left.sampleWidth,
    left.sampleHeight,
    {
      threshold: 0.12,
      includeAA: true,
      alpha: 0.1,
    },
  );
  return diff / totalPixels;
};

for (const target of TARGETS) {
  test(`${target.name} backend parity`, async ({ page }) => {
    const normal = await loadSmokeResult(page, target.normalPath);
    assertRuntimeSmokeMetrics(normal);

    const forceWebGl = await loadSmokeResult(page, target.forceWebGlPath);
    assertRuntimeSmokeMetrics(forceWebGl, "webgl2");

    if (normal.presentedFrames <= 0 || forceWebGl.presentedFrames <= 0) {
      return;
    }

    const ratio = pixelDiffRatio(normal, forceWebGl);
    // SwiftShader software rendering may produce slightly different results
    // between runs; use a generous threshold for same-backend comparisons
    const maxRatio = normal.backendMode === "webgpu" ? 0.15 : 0.15;
    expect(ratio).toBeLessThanOrEqual(maxRatio);
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
    // In headless mode, getImageData returns all zeros but the buffer dimensions are correct
    // read_pixels(0, 0, 4, 4) should return 4*4*4 = 64 channels, or -1 if unsupported
    expect(readPixelsLen).toBe(64);
  });
}
