# Architecture Draft (Ebiten inspired)

## Goals

- まず 2D を安定実装し、後で 3D に拡張
- 実装差し替え可能なコントラクト層を先に固める
- バックエンドを `wgpu-native(desktop)` / `WebGPU|WebGL(web)` で統一

## Ebiten から移植する強み

1. 固定 timestep (`Update`) と可変描画 (`Draw`) の分離
2. オフスクリーン描画 → 最終スクリーン合成
3. DrawCommand を 1 フレーム単位で集約してドライバ呼び出しを削減
4. 画像リソース管理（atlas / managed or unmanaged の区別）
5. UI/Platform と GraphicsDriver の明確な分離
6. Tick 時点の入力スナップショット（1 tick 内の一貫性）
7. Shader の Frontend/IR/Uniform 正規化を分離して backend 差分を局所化

## Ebiten Outline -> kagura

- `ebiten/run.go`
  - 役割: 公開 `Game` インターフェース、`RunGame` エントリ
  - 移植先: `core`（公開契約） + `runtime`（実行）
- `internal/ui/*`
  - 役割: プラットフォーム差異吸収、ループ駆動、window/input 取得
  - 移植先: `platform` + `runtime`
- `internal/graphicsdriver/*`
  - 役割: 描画バックエンド抽象と実装（Metal/GL/DX）
  - 移植先: `gfx`（抽象） + `gfx_wgpu_native` / `gfx_webgpu` / `gfx_webgl`（実装）
- `internal/graphicscommand/*`
  - 役割: DrawCommand のキュー化、merge、flush
  - 移植先: `gfx`（CommandQueue）
- `internal/atlas/*`
  - 役割: テクスチャ atlas と managed/unmanaged 画像管理
  - 移植先: `asset`（後段）
- `internal/inputstate/*`
  - 役割: tick 単位入力スナップショット
  - 移植先: `platform`（収集） + `core`（InputSnapshot 型）
- `internal/clock/*`
  - 役割: TPS/FPS と update 回数調整
  - 移植先: `core`（FixedStep）

## Proposed Modules

- `core`:
  - ゲームループ契約、固定 timestep、フレーム統計
  - 純粋関数中心（テスト容易）
- `runtime`:
  - `core` 契約を使ってループを実行
  - single-thread / multi-thread 戦略を隠蔽
- `platform`:
  - window, event, input の抽象
  - desktop(glfw), web(canvas/dom) 実装
- `gfx`:
  - `RenderBackend` 抽象と draw command
  - ShaderFrontend / UniformCanonicalizer / BuiltinShaderSource の契約
  - 将来 `gfx_wgpu`, `gfx_webgl` に分離
- `asset`:
  - image/shader/material/atlas の repository 契約
- `text`:
  - `mizchi/font` ベースの shaping/raster 契約
- `ui`:
  - `mizchi/layout` ベースの layout/input/render bridge 契約
- `ai`:
  - sensor/policy/actuator/scheduler の4分割契約
  - fixed tick で決定論的に実行
- `gfx_wgpu_native`(planned):
  - `~/Downloads/wgpu` の FFI をベースに desktop 実装
- `gfx_webgpu` / `gfx_webgl`(planned):
  - browser 実装
- `asset`(planned):
  - texture, shader, pipeline, hot-reload
- `text`(planned):
  - `mizchi/font` を利用した glyph 生成
- `ui`(planned):
  - `mizchi/layout` を利用した 2D UI レイアウト

## Backend Strategy

- Desktop:
  - `wgpu-native + GLFW` を最初の実行ターゲットにする
  - `~/Downloads/wgpu` の三角形デモを最初の Green とする
- Web:
  - 第一候補 WebGPU
  - フォールバック WebGL2 (必要なら `crater/js` の実装資産を利用)

## First Vertical Slice (実装開始点)

1. `core` の `step_fixed_timestep` を先に実装
2. `platform` に最小 desktop 実装（window size / poll / close）
3. `gfx_wgpu_native` に最小実装（clear + triangle）
4. `runtime.run_loop` で `Update -> Draw -> Present` を接続
5. ここまで通ったら command queue を導入して draw call 削減へ進む

## 3D 拡張方針

- 2D DrawCommand を RenderPass/RenderItem に一般化
- Camera/Transform/Material を追加しても 2D API を壊さない
- `core` API は 2D/3D 共通の Tick/Frame 契約を維持

## Boundary Rule

- `core` は `platform/gfx` を import しない
- `ai` は `gfx` を import しない
- `ui` は `platform` へ直接依存せず `core.InputSnapshot` を入力にする
- `platform` と `gfx` は `SurfaceToken` で接続する
