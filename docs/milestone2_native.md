# Milestone 2 Native (WGPU + GLFW)

`~/Downloads/wgpu` の最小三角形実装を `kagura` に移植した。

## Added Packages

- `src/gfx_wgpu_native`
  - `glfw_bindings.mbt`
  - `wgpu_bindings.mbt`
  - `wgpu_native_stub.m`
  - `backend.mbt` (`run_triangle_demo`)
- `src/examples/native_triangle`
  - `main_native.mbt` (`@wgpu_native.run_triangle_demo()`)
  - `main_stub.mbt` (non-native target 用)

## Setup

```bash
bash scripts/setup-wgpu-native.sh
```

## Run

```bash
moon build src/examples/native_triangle --target native
moon run src/examples/native_triangle --target native
```

## Notes

- `gfx_wgpu_native` は native 専用 (`supported-targets: ["native"]`)
- C stub は macOS + Metal + GLFW 前提
- `moon check --target js` には影響しない
- `link.native.cc-link-flags` は最終実行 package 側（`src/examples/native_triangle/moon.pkg`）にも必要
