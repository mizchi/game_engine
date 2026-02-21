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

for (const target of TARGETS) {
  test(`${target.name} audio smoke`, async ({ page }) => {
    const result = await loadSmokeResult(page, target.normalPath);
    expect(result.status).toBe("ok");
    // Audio smoke line should be present in output
    const audioMatch = result.output.match(/audio_smoke: ok init=(true|false)/);
    expect(audioMatch).not.toBeNull();
    if (audioMatch && audioMatch[1] === "true") {
      // If audio initialized, check written frames
      const writtenMatch = result.output.match(/written=(\d+)/);
      expect(writtenMatch).not.toBeNull();
      if (writtenMatch) {
        expect(Number(writtenMatch[1])).toBe(256);
      }
    }
  });
}

for (const target of TARGETS) {
  test(`${target.name} font smoke`, async ({ page }) => {
    const result = await loadSmokeResult(page, target.normalPath);
    expect(result.status).toBe("ok");
    // Font smoke line should be present in output
    const fontMatch = result.output.match(
      /font_smoke: ok load=(true|false)/,
    );
    expect(fontMatch).not.toBeNull();
    if (fontMatch && fontMatch[1] === "true") {
      // If font loaded, check measure dimensions
      const wMatch = result.output.match(/font_smoke:.*w=([0-9.]+)/);
      const hMatch = result.output.match(/font_smoke:.*h=([0-9.]+)/);
      expect(wMatch).not.toBeNull();
      expect(hMatch).not.toBeNull();
      if (wMatch && hMatch) {
        expect(Number(wMatch[1])).toBeGreaterThan(0);
        expect(Number(hMatch[1])).toBeGreaterThan(0);
      }
    }
  });
}

for (const target of TARGETS) {
  test(`${target.name} font smoke full`, async ({ page }) => {
    const result = await loadSmokeResult(page, target.normalPath);
    expect(result.status).toBe("ok");
    const fullMatch = result.output.match(
      /font_smoke_full: ok load=(true|false)/,
    );
    expect(fullMatch).not.toBeNull();
    if (fullMatch && fullMatch[1] === "true") {
      const textW = result.output.match(/font_smoke_full:.*text_w=([0-9.]+)/);
      const charW = result.output.match(/font_smoke_full:.*char_w=([0-9.]+)/);
      const size12W = result.output.match(/font_smoke_full:.*size12_w=([0-9.]+)/);
      expect(textW).not.toBeNull();
      expect(charW).not.toBeNull();
      expect(size12W).not.toBeNull();
      if (textW && charW && size12W) {
        const tw = Number(textW[1]);
        const cw = Number(charW[1]);
        const sw = Number(size12W[1]);
        // multi-char text should be wider than single char
        expect(tw).toBeGreaterThan(0);
        expect(tw).toBeGreaterThan(cw);
        // 12px should be smaller than 24px
        expect(sw).toBeLessThan(cw);
      }
    }
  });
}

for (const target of TARGETS) {
  test(`${target.name} font smoke CJK`, async ({ page }) => {
    const result = await loadSmokeResult(page, target.normalPath);
    expect(result.status).toBe("ok");
    const cjkMatch = result.output.match(
      /font_smoke_cjk: ok load=(true|false)/,
    );
    expect(cjkMatch).not.toBeNull();
    if (cjkMatch && cjkMatch[1] === "true") {
      const hiraganaW = result.output.match(/font_smoke_cjk:.*hiragana_w=([0-9.]+)/);
      const kanjiW = result.output.match(/font_smoke_cjk:.*kanji_w=([0-9.]+)/);
      expect(hiraganaW).not.toBeNull();
      expect(kanjiW).not.toBeNull();
      if (hiraganaW && kanjiW) {
        // CJK text should have positive width
        expect(Number(hiraganaW[1])).toBeGreaterThan(0);
        expect(Number(kanjiW[1])).toBeGreaterThan(0);
        // 3 hiragana chars should be wider than 2 kanji chars
        expect(Number(hiraganaW[1])).toBeGreaterThan(Number(kanjiW[1]));
      }
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
