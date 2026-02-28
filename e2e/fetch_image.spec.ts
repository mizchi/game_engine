import { expect, test } from "@playwright/test";

type FetchImageResult = {
  status: string;
  frames: number;
  hasWebGPU: boolean;
  error?: string;
};

test("fetch_image loads and renders sprite", async ({ page }) => {
  await page.goto("/e2e/fixtures/fetch_image.html");

  // Wait for __fetchImageResult to be set (first frame or timeout)
  await page.waitForFunction(
    () => Boolean((window as { __fetchImageResult?: FetchImageResult }).__fetchImageResult),
    null,
    { timeout: 10_000 },
  );

  const result = await page.evaluate(() => {
    return (window as { __fetchImageResult?: FetchImageResult }).__fetchImageResult;
  });

  expect(result).toBeTruthy();
  expect(result!.status).toBe("ok");
  expect(result!.frames).toBeGreaterThan(0);
});

test("fetch_image canvas has non-zero pixels when WebGPU available", async ({ page }) => {
  await page.goto("/e2e/fixtures/fetch_image.html");

  await page.waitForFunction(
    () => Boolean((window as { __fetchImageResult?: { status?: string } }).__fetchImageResult),
    null,
    { timeout: 10_000 },
  );

  const result = await page.evaluate(() => {
    return (window as { __fetchImageResult?: FetchImageResult }).__fetchImageResult;
  });

  expect(result).toBeTruthy();

  if (!result!.hasWebGPU) {
    test.skip(true, "WebGPU not available in this environment");
    return;
  }

  // Wait a couple more frames for rendering to stabilize
  await page.waitForFunction(
    () => {
      const r = (window as { __fetchImageResult?: FetchImageResult }).__fetchImageResult;
      return r && r.frames >= 3;
    },
    null,
    { timeout: 10_000 },
  );

  // Read pixels from the canvas to verify non-zero content
  const hasContent = await page.evaluate(() => {
    const canvas = document.querySelector("#app") as HTMLCanvasElement | null;
    if (!canvas) return false;

    // Use a 2D offscreen canvas to capture WebGPU canvas content
    const offscreen = document.createElement("canvas");
    offscreen.width = canvas.width;
    offscreen.height = canvas.height;
    const ctx2d = offscreen.getContext("2d");
    if (!ctx2d) return false;

    ctx2d.drawImage(canvas, 0, 0);
    const imageData = ctx2d.getImageData(0, 0, offscreen.width, offscreen.height);
    const pixels = imageData.data;

    // Check if any pixel has non-zero RGB values
    for (let i = 0; i < pixels.length; i += 4) {
      if (pixels[i] > 0 || pixels[i + 1] > 0 || pixels[i + 2] > 0) {
        return true;
      }
    }
    return false;
  });

  expect(hasContent).toBe(true);
});
