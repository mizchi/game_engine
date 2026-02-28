import { defineConfig, type Plugin } from "vite";
import { execSync } from "child_process";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import { copyFileSync, existsSync, watch as fsWatch } from "fs";

const __dirname = dirname(fileURLToPath(import.meta.url));

const moonbitSrc = resolve(__dirname, "../guest/moonbit/src");
const moonbitOut = resolve(
  __dirname,
  "../guest/moonbit/_build/wasm/debug/build/wasm_game_guest.wasm",
);
const publicWasm = resolve(__dirname, "public/game.wasm");

function wasmHmrPlugin(): Plugin {
  let abortController: AbortController | null = null;

  return {
    name: "wasm-hmr",
    configureServer(server) {
      // Watch public/game.wasm via Vite's built-in watcher
      server.watcher.add(publicWasm);
      server.watcher.on("change", (path) => {
        if (path === publicWasm) {
          console.log("[wasm-hmr] game.wasm changed, sending HMR update");
          server.ws.send({ type: "custom", event: "wasm-update", data: {} });
        }
      });

      // Watch MoonBit source files with fs.watch and auto-rebuild
      if (existsSync(moonbitSrc)) {
        abortController = new AbortController();
        fsWatch(
          moonbitSrc,
          { recursive: true, signal: abortController.signal },
          (_event, filename) => {
            if (!filename?.endsWith(".mbt")) return;
            console.log(`[wasm-hmr] MoonBit source changed: ${filename}`);
            try {
              execSync("moon build --target wasm", {
                cwd: resolve(__dirname, "../guest/moonbit"),
                stdio: "pipe",
              });
              if (existsSync(moonbitOut)) {
                copyFileSync(moonbitOut, publicWasm);
              }
              console.log("[wasm-hmr] MoonBit rebuild + copy OK");
            } catch (e: unknown) {
              const stderr =
                e && typeof e === "object" && "stderr" in e
                  ? String((e as { stderr: unknown }).stderr)
                  : String(e);
              console.error("[wasm-hmr] Build failed:\n" + stderr);
            }
          },
        );
      }
    },
    buildEnd() {
      abortController?.abort();
    },
  };
}

export default defineConfig({
  plugins: [wasmHmrPlugin()],
});
