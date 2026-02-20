import { spawnSync } from "node:child_process";
import { expect, test } from "@playwright/test";

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

test.describe("runtime smoke native", () => {
  test.skip(process.platform !== "darwin", "native smoke is macOS-only");
  test.setTimeout(120_000);

  test("runtime_smoke --target native", () => {
    const result = runMoon(["run", "src/examples/runtime_smoke", "--target", "native"]);
    const output = `${result.stdout}\n${result.stderr}`;
    expect(result.status, output).toBe(0);
    expect(output).toContain("runtime_smoke(native): ok");
  });

  test("runtime_smoke_native --target native", () => {
    const result = runMoon(["run", "src/examples/runtime_smoke_native", "--target", "native"]);
    const output = `${result.stdout}\n${result.stderr}`;
    expect(result.status, output).toBe(0);
    expect(output).toContain("runtime_smoke_native: ok (real)");
    const probe = output.match(
      /runtime_smoke_native_probe:\s*tex_seed=(\d+)\s+source_gen=(\d+)\s+atlas_gen=(\d+)\s+atlas_rgb=(\d+),(\d+),(\d+)/,
    );
    expect(probe, output).not.toBeNull();
    if (probe == null) {
      return;
    }
    expect(Number(probe[1])).toBe(801);
    expect(Number(probe[2])).toBe(2);
    expect(Number(probe[3])).toBe(2);
    expect(Number(probe[4])).toBe(42);
    expect(Number(probe[5])).toBe(43);
    expect(Number(probe[6])).toBe(44);

    // Verify read_pixels probe
    const rpMatch = output.match(/read_pixels_len=(-?\d+)/);
    expect(rpMatch, output).not.toBeNull();
    if (rpMatch != null) {
      const readPixelsLen = Number(rpMatch[1]);
      // read_pixels(0, 0, 4, 4) = 4*4*4 = 64 channels
      expect(readPixelsLen).toBe(64);
    }

    // Verify read_pixels_4x1 contains actual pixel data (not "none")
    const rp4x1Match = output.match(/read_pixels_4x1=(none|\d+(?:,\d+){15})/);
    expect(rp4x1Match, output).not.toBeNull();
    if (rp4x1Match != null) {
      expect(rp4x1Match[1]).not.toBe("none");
      const pixels = rp4x1Match[1].split(",").map(Number);
      expect(pixels.length).toBe(16);
      // All values should be valid 0-255 range
      for (const ch of pixels) {
        expect(ch).toBeGreaterThanOrEqual(0);
        expect(ch).toBeLessThanOrEqual(255);
      }
    }

    // Verify command_count (tile + sprite)
    const ccMatch = output.match(/command_count=(\d+)/);
    expect(ccMatch, output).not.toBeNull();
    if (ccMatch != null) {
      expect(Number(ccMatch[1])).toBe(3);
    }
  });
});
