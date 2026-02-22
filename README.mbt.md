# mizchi/kagura

仮

MoonBit 向け 2D(将来 3D) ゲームエンジン。

- API/実装の責務を分離
- Ebiten の良い設計（固定 timestep、描画コマンド集約、オフスクリーン合成、バックエンド抽象）を移植
- デスクトップは wgpu-native、ブラウザは WebGPU / WebGL を対象
- 現在は **契約先行 + 最小実装**（ランタイム smoke を通す stub 実装）

## 参考実装

- `hajimehoshi/ebiten`
- `mizchi/layout`
- `mizchi/font`
- `~/Downloads/wgpu` の最小三角形デモ

## 現在の状態

- `core`: `Game`, `RunOptions`, `FixedStep*` の契約
- `platform`: window/event/input 抽象
- `gfx`: GraphicsDriver / CommandQueue + ShaderFrontend / UniformCanonicalizer + backend factory 抽象
- `asset`: image/shader/material/atlas 抽象（SourceImageBinding ファクトリ付き）
- `text`: font shaping / glyph atlas / text batch 抽象（GlyphAtlas → GPU テクスチャ同期済み）
- `ui`: layout/input/render bridge 抽象
- `ai`: sensor/policy/actuator/scheduler 抽象
- `runtime`: ループ統合 API 抽象
- `gfx_wgpu_native`: native 向け最小三角形バックエンド（Milestone 2）
- `examples/native_runtime_hooks` / `examples/web_runtime_hooks`: 実行環境 hook 境界

契約先行だが、主要モジュールはランタイム統合のための最小実装が入っている。

## Smoke Checks

```bash
moon run src/examples/runtime_smoke --target js
moon run src/examples/runtime_smoke_native --target native
moon build src/examples/native_triangle --target native
pnpm e2e:smoke
```

詳細は `docs/architecture.md`, `docs/module_boundaries.md`, `docs/implementation_outline.md`, `docs/roadmap.md`, `docs/ebiten_reference.md`, `docs/shader_research.md`, `docs/ai_contract.md`, `docs/milestone2_native.md` を参照。
