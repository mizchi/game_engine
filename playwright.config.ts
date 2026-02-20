import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  retries: process.env.CI ? 2 : 0,
  use: {
    baseURL: "http://127.0.0.1:4173",
    browserName: "chromium",
    headless: true,
    launchOptions: {
      args: [
        "--enable-unsafe-swiftshader",
        "--enable-webgl",
        "--use-gl=swiftshader",
      ],
    },
  },
  webServer: {
    command: "node scripts/serve-wasm-smoke.mjs",
    url: "http://127.0.0.1:4173/healthz",
    timeout: 120_000,
    reuseExistingServer: !process.env.CI,
  },
});
