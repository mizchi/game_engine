# Getting Started

[日本語](getting_started_ja.md)

## Prerequisites

- [MoonBit](https://www.moonbitlang.com/)
- Node.js 24+
- pnpm
- [just](https://github.com/casey/just)

## Install

```bash
pnpm install
```

## Run in Browser

```bash
just dev flappy_bird
```

Builds and starts a local server. Open `http://localhost:8080` in a WebGPU-capable browser.

Other examples work the same way:

```bash
just dev survivor
just dev action_rpg
just dev scene_demo
```

## CLI Smoke Test

```bash
(cd examples/runtime_smoke && moon run src --target js)
```

Expected output:

```text
runtime_smoke(js): ok (hooked)
```

## Native Run (macOS only)

> Native builds currently support macOS only. Windows and Linux support is planned.

```bash
bash scripts/setup-wgpu-native.sh
(cd examples/runtime_smoke_native && moon run src --target native)
```

## Ongoing Verification

```bash
just check target=js
just test target=js
pnpm e2e:smoke
```
