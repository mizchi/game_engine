# Ebiten Reference Map

本リポジトリの契約 API が、Ebiten のどの実装を参考にしているかの対応表。

| kagura | Ebiten reference |
|---|---|
| `core.Game` / `core.run_game` | `run.go` (`Game`, `RunGame`) |
| `core.FixedStep*` | `internal/clock/clock.go`, `internal/ui/context.go` |
| `core.FinalScreenDrawer` | `run.go`, `gameforui.go` |
| `platform.PlatformDriver` | `internal/ui/ui.go`, `internal/ui/ui_glfw.go`, `internal/ui/input_*.go`, `internal/inputstate/inputstate.go` |
| `platform.SurfaceProvider` | `internal/ui/ui_glfw.go`, `internal/ui/ui_js.go` |
| `gfx.GraphicsDriver` | `internal/graphicsdriver/graphics.go` |
| `gfx.GraphicsBackendFactory` | `internal/graphicsdriver/graphics.go` + `internal/ui/*` の初期化境界 |
| `gfx.ShaderFrontend` | `internal/graphics/shader.go` (`CompileShader`, `CalcSourceHash`), `internal/shader/shader.go` |
| `gfx.UniformCanonicalizer` | `internal/ui/shader.go` (`AppendUniforms`), `internal/graphicscommand/commandqueue.go` (`prependPreservedUniforms`), `internal/shaderir/program.go` (`FilterUniformVariables`) |
| `gfx.BuiltinShaderSourceRepo` | `internal/builtinshader/shader.go`, `shader.go` (builtin cache), `internal/atlas/shader.go` |
| `gfx.CommandQueue` | `internal/graphicscommand/commandqueue.go` |
| `asset.ImageRepository/AtlasAllocator` | `internal/atlas/image.go` |
| `gfx.ImageHandle` 想定の管理方針 | `internal/atlas/image.go` |
| `text/ui/ai` | Ebiten に直接対応はないため拡張設計（`mizchi/font`, `mizchi/layout`, AI policy） |
| `runtime.run_loop` | `internal/ui/run.go`, `internal/ui/context.go` |
