import { spawnSync } from "node:child_process";
import { createServer } from "node:http";
import { existsSync, readFileSync, statSync } from "node:fs";
import { extname, join, normalize } from "node:path";
import process from "node:process";

const ROOT = process.cwd();
const HOST = "127.0.0.1";
const PORT = Number.parseInt(process.env.PORT ?? "4173", 10);

const CONTENT_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".map": "application/json; charset=utf-8",
  ".wasm": "application/wasm",
  ".css": "text/css; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
};

const buildRuntimeSmoke = (target) => {
  const result = spawnSync(
    "moon",
    ["build", "src", "--target", target],
    { cwd: join(ROOT, "examples", "runtime_smoke"), stdio: "inherit" },
  );
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
};

buildRuntimeSmoke("wasm");
buildRuntimeSmoke("wasm-gc");

const buildJsExample = (name) => {
  const result = spawnSync("moon", ["build", "src", "--target", "js"], {
    cwd: join(ROOT, "examples", name),
    stdio: "inherit",
  });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
};
buildJsExample("fetch_image");

const resolvePath = (pathname) => {
  const normalized = normalize(pathname).replace(/^(\.\.[/\\])+/, "");
  const withoutLeadingSlash = normalized.startsWith("/")
    ? normalized.slice(1)
    : normalized;
  const filePath = join(ROOT, withoutLeadingSlash);
  if (!filePath.startsWith(ROOT)) {
    return null;
  }
  return filePath;
};

const serveFile = (res, filePath) => {
  if (!existsSync(filePath)) {
    res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
    res.end("not found");
    return;
  }
  const stat = statSync(filePath);
  if (!stat.isFile()) {
    res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
    res.end("not found");
    return;
  }
  const contentType = CONTENT_TYPES[extname(filePath)] ?? "application/octet-stream";
  const body = readFileSync(filePath);
  res.writeHead(200, {
    "content-type": contentType,
    "cache-control": "no-store",
  });
  res.end(body);
};

const server = createServer((req, res) => {
  const url = new URL(req.url ?? "/", `http://${HOST}:${PORT}`);
  if (url.pathname === "/healthz") {
    res.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
    res.end("ok");
    return;
  }
  const pathname =
    url.pathname === "/" ? "/e2e/fixtures/runtime_smoke_wasm.html" : url.pathname;
  const filePath = resolvePath(pathname);
  if (filePath == null) {
    res.writeHead(403, { "content-type": "text/plain; charset=utf-8" });
    res.end("forbidden");
    return;
  }
  serveFile(res, filePath);
});

server.listen(PORT, HOST, () => {
  console.log(`[e2e] wasm smoke server ready: http://${HOST}:${PORT}`);
});

const shutdown = () => {
  server.close(() => {
    process.exit(0);
  });
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
