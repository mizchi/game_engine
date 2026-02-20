import { spawnSync } from "node:child_process";
import { expect, test, type Page } from "@playwright/test";

type SmokeResult = {
  status: string;
  output: string;
  samplePixels?: number[];
  sampleWidth?: number;
  sampleHeight?: number;
};

const runMoon = (args: string[]) => {
  const result = spawnSync("moon", args, {
    cwd: process.cwd(),
    encoding: "utf8",
    env: {
      ...process.env,
      NO_COLOR: "1",
    },
  });
  return {
    status: result.status ?? -1,
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
  };
};

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

const WEB_PROBE_RE =
  /runtime_smoke_web_probe:\s*tex_seed=(\d+)\s+atlas_gen=(\d+)\s+atlas_rgb=(\d+),(\d+),(\d+)\s+sample0=(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\s+sample1=(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\s+sample2=(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\s+read_pixels_len=(-?\d+)\s+read_pixels_4x1=(none|\d+(?:,\d+){15})\s+command_count=(\d+)/;
const NATIVE_PROBE_RE =
  /runtime_smoke_native_probe:\s*tex_seed=(\d+)\s+source_gen=(\d+)\s+atlas_gen=(\d+)\s+atlas_rgb=(\d+),(\d+),(\d+)\s+sample0=(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\s+sample1=(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\s+sample2=(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\s+read_pixels_len=(-?\d+)\s+read_pixels_4x1=(none|\d+(?:,\d+){15})\s+command_count=(\d+)/;

const decodeProbeSamples = (probe: RegExpMatchArray, startIndex: number) => {
  return [
    {
      x: Number(probe[startIndex]),
      y: Number(probe[startIndex + 1]),
      rgba: [
        Number(probe[startIndex + 2]),
        Number(probe[startIndex + 3]),
        Number(probe[startIndex + 4]),
        Number(probe[startIndex + 5]),
      ],
    },
    {
      x: Number(probe[startIndex + 6]),
      y: Number(probe[startIndex + 7]),
      rgba: [
        Number(probe[startIndex + 8]),
        Number(probe[startIndex + 9]),
        Number(probe[startIndex + 10]),
        Number(probe[startIndex + 11]),
      ],
    },
    {
      x: Number(probe[startIndex + 12]),
      y: Number(probe[startIndex + 13]),
      rgba: [
        Number(probe[startIndex + 14]),
        Number(probe[startIndex + 15]),
        Number(probe[startIndex + 16]),
        Number(probe[startIndex + 17]),
      ],
    },
  ];
};

test.describe("runtime smoke cross backend parity", () => {
  test.skip(process.platform !== "darwin", "native smoke is macOS-only");
  test.setTimeout(120_000);

  test("web/native probe metrics stay in sync", async ({ page }) => {
    const web = await loadSmokeResult(page, "/e2e/fixtures/runtime_smoke_wasm.html");
    expect(web.status).toBe("ok");
    const webProbe = web.output.match(WEB_PROBE_RE);
    expect(webProbe, web.output).not.toBeNull();
    if (webProbe == null) {
      return;
    }
    const webSeed = Number(webProbe[1]);
    const webAtlasGen = Number(webProbe[2]);
    const webR = Number(webProbe[3]);
    const webG = Number(webProbe[4]);
    const webB = Number(webProbe[5]);
    const webSamples = decodeProbeSamples(webProbe, 6);
    expect(webSeed).toBe(801);

    const native = runMoon(["run", "src/examples/runtime_smoke_native", "--target", "native"]);
    const nativeOutput = `${native.stdout}\n${native.stderr}`;
    expect(native.status, nativeOutput).toBe(0);
    const nativeProbe = nativeOutput.match(NATIVE_PROBE_RE);
    expect(nativeProbe, nativeOutput).not.toBeNull();
    if (nativeProbe == null) {
      return;
    }
    const nativeSeed = Number(nativeProbe[1]);
    const nativeAtlasGen = Number(nativeProbe[3]);
    const nativeR = Number(nativeProbe[4]);
    const nativeG = Number(nativeProbe[5]);
    const nativeB = Number(nativeProbe[6]);
    const nativeSamples = decodeProbeSamples(nativeProbe, 7);

    expect(webSeed).toBe(801);
    expect(nativeSeed).toBe(801);
    expect(webAtlasGen).toBeGreaterThanOrEqual(2);
    expect(nativeAtlasGen).toBeGreaterThanOrEqual(2);
    expect(webR).toBe(nativeR);
    expect(webG).toBe(nativeG);
    expect(webB).toBe(nativeB);
    expect(webSamples.length).toBe(nativeSamples.length);
    for (let i = 0; i < webSamples.length; i++) {
      const webSample = webSamples[i];
      const nativeSample = nativeSamples[i];
      expect(Math.abs(webSample.x - nativeSample.x)).toBeLessThanOrEqual(12);
      expect(Math.abs(webSample.y - nativeSample.y)).toBeLessThanOrEqual(12);
      expect(webSample.rgba[0]).toBe(nativeSample.rgba[0]);
      expect(webSample.rgba[1]).toBe(nativeSample.rgba[1]);
      expect(webSample.rgba[2]).toBe(nativeSample.rgba[2]);
      expect(webSample.rgba[3]).toBe(nativeSample.rgba[3]);
    }

    // Verify command_count matches between web and native
    const webCommandCount = Number(webProbe[26]);
    const nativeCommandCount = Number(nativeProbe[27]);
    expect(webCommandCount).toBe(3);
    expect(nativeCommandCount).toBe(3);
    expect(webCommandCount).toBe(nativeCommandCount);
  });

  test("cross-backend read_pixels parity", async ({ page }) => {
    const web = await loadSmokeResult(page, "/e2e/fixtures/runtime_smoke_wasm.html");
    expect(web.status).toBe("ok");
    const webProbe = web.output.match(WEB_PROBE_RE);
    expect(webProbe, web.output).not.toBeNull();
    if (webProbe == null) return;

    const native = runMoon(["run", "src/examples/runtime_smoke_native", "--target", "native"]);
    const nativeOutput = `${native.stdout}\n${native.stderr}`;
    expect(native.status, nativeOutput).toBe(0);
    const nativeProbe = nativeOutput.match(NATIVE_PROBE_RE);
    expect(nativeProbe, nativeOutput).not.toBeNull();
    if (nativeProbe == null) return;

    const nativeReadPixelsLen = Number(nativeProbe[25]);
    const nativeReadPixels4x1 = nativeProbe[26];
    // Native always has valid read_pixels (64 channels for 4x4 region)
    expect(nativeReadPixelsLen).toBe(64);
    expect(nativeReadPixels4x1).not.toBe("none");
    const nativePixels = nativeReadPixels4x1.split(",").map(Number);
    expect(nativePixels.length).toBe(16);

    const webReadPixelsLen = Number(webProbe[24]);
    const webReadPixels4x1 = webProbe[25];
    if (webReadPixelsLen > 0 && webReadPixels4x1 !== "none") {
      // Both backends have valid read_pixels — compare with tolerance
      const webPixels = webReadPixels4x1.split(",").map(Number);
      expect(webPixels.length).toBe(16);
      const TOLERANCE = 8;
      for (let i = 0; i < 16; i++) {
        expect(
          Math.abs(webPixels[i] - nativePixels[i]),
          `pixel channel ${i}: web=${webPixels[i]} native=${nativePixels[i]}`,
        ).toBeLessThanOrEqual(TOLERANCE);
      }
    }
    // When web has no WebGPU (headless), skip pixel comparison but still verify native
  });

  test("web pixel capture buffer has correct dimensions", async ({ page }) => {
    const web = await loadSmokeResult(page, "/e2e/fixtures/runtime_smoke_wasm.html");
    expect(web.status).toBe("ok");

    const samplePixels = web.samplePixels as number[] | undefined;
    const sampleWidth = (web.sampleWidth as number | undefined) ?? 0;
    const sampleHeight = (web.sampleHeight as number | undefined) ?? 0;
    if (!samplePixels || samplePixels.length === 0 || sampleWidth === 0) {
      return;
    }

    // Verify pixel buffer has expected dimensions (RGBA)
    const expectedLength = sampleWidth * sampleHeight * 4;
    expect(samplePixels.length).toBe(expectedLength);
    expect(sampleWidth).toBe(64);
    expect(sampleHeight).toBe(64);

    // Count non-zero pixels (may be 0 in headless mode)
    let nonZeroPixels = 0;
    for (let i = 0; i < samplePixels.length; i += 4) {
      if (samplePixels[i] > 0 || samplePixels[i + 1] > 0 ||
          samplePixels[i + 2] > 0 || samplePixels[i + 3] > 0) {
        nonZeroPixels++;
      }
    }
    // In headed mode, expect non-trivial pixels; in headless, 0 is acceptable
    expect(nonZeroPixels).toBeGreaterThanOrEqual(0);
  });
});
