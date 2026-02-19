import { expect, test } from "@playwright/test";

const EXPECTED_OUTPUT = "runtime_smoke(js): ok (hooked)";

const CASES = [
  {
    name: "runtime_smoke wasm target",
    path: "/e2e/fixtures/runtime_smoke_wasm.html",
  },
  {
    name: "runtime_smoke wasm-gc target",
    path: "/e2e/fixtures/runtime_smoke_wasm_gc.html",
  },
] as const;

for (const item of CASES) {
  test(item.name, async ({ page }) => {
    await page.goto(item.path);
    await page.waitForFunction(() => {
      return Boolean((window as { __wasmSmoke?: { status?: string } }).__wasmSmoke?.status);
    });
    const result = await page.evaluate(() => {
      return (
        window as {
          __wasmSmoke?: {
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
          };
        }
      ).__wasmSmoke;
    });
    expect(result?.status).toBe("ok");
    expect(result?.output).toContain(EXPECTED_OUTPUT);
    expect(["webgpu", "webgl2"]).toContain(result?.backendMode);
    expect((result?.presentedFrames ?? 0) > 0).toBeTruthy();
    expect((result?.lastRegionCount ?? 0) > 0).toBeTruthy();
    expect((result?.lastTotalIndexCount ?? 0) > 0).toBeTruthy();
    expect((result?.lastVertexFloatCount ?? 0) > 0).toBeTruthy();
    expect((result?.lastIndexCount ?? 0) > 0).toBeTruthy();
    expect((result?.lastSrcImageCount ?? 0) > 0).toBeTruthy();
    expect((result?.lastUniformDwordCount ?? 0) > 0).toBeTruthy();
    expect(result?.payloadHasTriangle).toBeTruthy();
    expect((result?.payloadAx ?? 0) < -0.4).toBeTruthy();
    expect((result?.payloadAy ?? 0) < -0.4).toBeTruthy();
    expect((result?.payloadBx ?? 0) > 0.4).toBeTruthy();
    expect((result?.payloadBy ?? 0) < -0.4).toBeTruthy();
    expect((result?.payloadCx ?? 0) > 0.4).toBeTruthy();
    expect((result?.payloadCy ?? 0) > 0.4).toBeTruthy();
    expect((result?.payloadUniformR ?? 1) < 0.05).toBeTruthy();
    expect((result?.payloadUniformG ?? 1) < 0.05).toBeTruthy();
    expect((result?.payloadUniformB ?? 1) < 0.05).toBeTruthy();
    expect((result?.payloadUniformA ?? 1) < 0.05).toBeTruthy();
    expect((result?.payloadTextureSeed ?? 0) > 0).toBeTruthy();
  });
}
