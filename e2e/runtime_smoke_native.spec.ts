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
    expect(Number(probe[1])).toBe(901);
    expect(Number(probe[2])).toBe(2);
    expect(Number(probe[3])).toBe(2);
    expect(Number(probe[4])).toBe(42);
    expect(Number(probe[5])).toBe(43);
    expect(Number(probe[6])).toBe(44);
  });
});
