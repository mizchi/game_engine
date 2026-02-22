# kagura

A 2D-first (with future 3D) game engine for [MoonBit](https://www.moonbitlang.com/), inspired by [Ebiten](https://github.com/hajimehoshi/ebiten).

[日本語](README_ja.md)

## Features

- **Contract-first architecture** -- API contracts are defined before implementations, keeping the codebase modular and replaceable
- **Ebiten-inspired design** -- Fixed timestep updates, draw command batching, offscreen compositing, and backend abstraction
- **Cross-platform** -- Desktop via wgpu-native, browser via WebGPU / WebGL
- **Pure MoonBit** -- No CGo, no FFI beyond the graphics backend boundary

## Architecture

```
core/          Game loop contracts, fixed timestep, frame stats
platform/      Window / event / input abstraction (desktop + web)
gfx/           Graphics driver, command queue, shader frontend
runtime/       Game loop execution and integration
asset/         Image / shader / material / atlas repository
text/          Font shaping, glyph atlas (mizchi/font)
ui/            Layout / input / render bridge (mizchi/layout)
ai/            Sensor / policy / actuator / scheduler
draw2d/        2D drawing utilities
sprite2d/      Sprite system
tilemap2d/     Tilemap system
camera2d/      2D camera
vector/        Vector math
```

### Platform Support

| Target | Backend | Status |
|--------|---------|--------|
| Web (all OS) | WebGPU / WebGL2 | Supported |
| Native macOS | wgpu-native + Metal + GLFW | Supported |
| Native Linux | wgpu-native + Vulkan + GLFW | Planned |
| Native Windows | wgpu-native + D3D12/Vulkan + GLFW | Planned |

> JS builds (browser) work on any OS. Native builds currently support macOS only.

## Quick Start

### Prerequisites

- [MoonBit](https://www.moonbitlang.com/)
- Node.js 24+
- pnpm
- [just](https://github.com/casey/just)

### Run in Browser

```bash
pnpm install
just dev flappy_bird
```

Builds and serves at `http://localhost:8080`. Requires a WebGPU-capable browser (Chrome 113+, Edge 113+).

### Native (macOS only)

```bash
bash scripts/setup-wgpu-native.sh
(cd examples/runtime_smoke_native && moon run src --target native)
```

## Examples

| Example              | Description                        |
|----------------------|------------------------------------|
| `runtime_smoke`      | Minimal JS smoke test              |
| `runtime_smoke_native` | Minimal native smoke test        |
| `native_triangle`    | Native backend triangle demo       |
| `flappy_bird`        | 2D game loop with input handling   |
| `survivor`           | Multi-entity game with weapons/UI  |
| `action_rpg`         | Action RPG prototype               |
| `arena3d`            | 3D arena prototype                 |

Each example is an independent MoonBit module. Run with:

```bash
(cd examples/<name> && moon run src --target <js|native>)
```

## Documentation

### For Users

- [Getting Started](docs/user/getting_started.md)
- [Tutorials](docs/user/tutorials.md)
- [API Guide](docs/user/api_guide.md)

### For Contributors

- [Contributing Guide](CONTRIBUTING.md)
- [Architecture](docs/architecture.md)
- [Module Boundaries](docs/module_boundaries.md)
- [Roadmap](docs/roadmap.md)

## Verification

```bash
just fmt
just check target=js
just test target=js
just check target=native
just test target=native
pnpm e2e:smoke
```

## Dependencies

- [mizchi/image](https://mooncakes.io/docs/#/mizchi/image/) -- Image codec (PNG/BMP/JPEG)
- [mizchi/font](https://mooncakes.io/docs/#/mizchi/font/) -- Font rendering and shaping
- [mizchi/layout](https://mooncakes.io/docs/#/mizchi/layout/) -- Layout engine
- [mizchi/audio](https://mooncakes.io/docs/#/mizchi/audio/) -- Audio system
- [mizchi/svg](https://mooncakes.io/docs/#/mizchi/svg/) -- SVG rendering

## License

Apache-2.0
