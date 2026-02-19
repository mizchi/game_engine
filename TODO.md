# TODO (Ebiten 同等機能ロードマップ)

## ゴール再確認

- 目標は「Ebiten と同等の 2D ゲームエンジン機能」を MoonBit で提供すること。
- 優先は「ブラウザ(WebGPU/WebGL) と Native(macOS wgpu) の両方で早期に同じゲームロジックを動かすこと」。
- 3D 拡張は 2D の API/実装が安定してから着手する。

## 実装状況スナップショット (2026-02-19)

- `moon test --target native`: 62 passed / 0 failed
- `moon test --target js`: 65 passed / 0 failed
- `moon run src/examples/runtime_smoke --target js`: pass (`runtime_smoke(js): ok (hooked)`)
- `moon run src/examples/runtime_smoke_native --target native`: pass (`runtime_smoke_native: ok (real)`)
- `pnpm e2e:smoke` (Playwright wasm/wasm-gc): 2 passed / 0 failed

判定基準:

- `完了`: 最小実行までつながっており、テスト/スモークで確認済み
- `部分`: 契約はあるが stub 最小実装、または本実装が未接続
- `未着手`: 契約や実装が不足

## Ebiten 機能群に対する実装状況

| 機能領域 | Ebiten 参照 | 現状 | 判定 |
|---|---|---|---|
| Game ループ契約 (`Game/Layout/Update/Draw`) | `run.go`, `gameforui.go` | `src/core/contracts.mbt`, `src/runtime/contracts.mbt` に契約と最小ループあり | 部分 |
| 固定 timestep 計画 | `internal/clock/clock.go`, `internal/ui/context.go` | `step_fixed_timestep` 実装 + 単体テストあり (`src/core/fixed_timestep*.mbt`) | 完了 |
| Platform 抽象 (Desktop) | `internal/ui/ui_glfw.go` | `DesktopGlfwPlatform` + hook 注入 (`src/platform/contracts.mbt`) | 部分 |
| Platform 抽象 (Web) | `internal/ui/ui_js.go` | `WebCanvasPlatform` + hook 注入 (`src/platform/contracts.mbt`) | 部分 |
| Window/System API (fullscreen/cursor/monitor/deviceScale/vsync/close) | `run.go`, `internal/ui/ui.go`, `internal/ui/ui_glfw.go` | `PlatformDriver` API + wbtest 契約固定。Desktop は runtime bridge 経由で GLFW(close/fullscreen/cursor/content-scale/attention) を部分接続、Web は js runtime hook で DOM(fullscreen/cursor/close/attention/dpr) を部分接続 | 部分 |
| Platform-Gfx 境界 (SurfaceToken) | `ui_glfw.go`, `ui_js.go` | `src/platform/surface_contracts.mbt` で token 化済み | 部分 |
| GraphicsDriver 抽象 | `internal/graphicsdriver/graphics.go` | begin/end/new_image/new_shader/draw_triangles 契約 + stub 実装 | 部分 |
| Native backend (wgpu + GLFW) | graphics driver 実装群 | `src/gfx_wgpu_native` で三角形描画まで実装。draw command のメタデータ（drawCalls/pipeline/uniform/blend/dst/shader/index/region/payload-count）を runtime bridge に伝播済み。先頭三角形について position/UV + uniform + src_image_id を dynamic WGSL pipeline へ反映する最小経路を追加。`runtime_smoke_native` で実行確認 | 部分 |
| Web backend (WebGPU/WebGL) | JS backend 群 | hook 経由で canvas/context 初期化 + clear pass + drawCalls 分の三角形描画 + WebGPU→WebGL2 fallback まで接続。draw command のメタデータ（pipeline/uniform/blend/dst/shader/index/region/payload-count）伝播済み。`runtime_smoke` wasm e2e で payload-count 経路を確認。頂点/UV/texture/uniform を使う実 draw path は未実装 | 部分 |
| CommandQueue 集約/flush | `internal/graphicscommand/commandqueue.go` | `SimpleCommandQueue` で pipeline/texture(blit先)/blend/uniform/index 条件の merge を実装 | 部分 |
| Image/Atlas 管理 | `internal/atlas/image.go` | `SimpleImageRepository`/`SimpleShaderRepository`/`SimpleMaterialRepository` と `SimpleAtlasAllocator` の最小実装を追加（高度な管理戦略は未実装） | 部分 |
| Shader Frontend/Hash | `internal/graphics/shader.go`, `internal/shader/shader.go` | source 前処理 + entrypoint/unit/src-image 含む hash を実装。`//kage:unit` directive（pixels/texels）の解釈を追加（Kage本体は未実装） | 部分 |
| Uniform 正規化 | `internal/ui/shader.go`, `internal/shaderir/program.go` | layout 長（preserved/user）正規化 + source の識別子境界に基づく unused uniform 0化を実装 | 部分 |
| Builtin shader source | `internal/builtinshader/shader.go` | filter/address/color_m 差分の WGSL source 生成 + lazy cache + clear/evict を実装 | 部分 |
| Input snapshot 一貫性 | `internal/inputstate/inputstate.go` | Platform hook から tick ごとに取得する経路を追加。Web(JS hooks) は cursor/wheel/pressed_keys/mouse buttons/touches/gamepads の最小実装、Native(GLFW hooks) は cursor/wheel/pressed_keys/mouse buttons + gamepads + Cocoa touch 取得（touch 無効環境では left-click fallback）まで接続済み | 部分 |
| 共通 2D payload decoder | `internal/graphicscommand/command.go` | `src/payload2d` に頂点/indices/uniform/src_image_id の decode 契約を分離。native hook で利用開始（後で独立 repo へ切り出し可能） | 部分 |
| Text rendering | `text/v2` | `src/text/contracts.mbt` 契約のみ | 未着手 |
| UI レイアウト統合 | Ebiten外 (拡張) | `src/ui/contracts.mbt` 契約のみ | 未着手 |
| AI tick 実行基盤 | Ebiten外 (拡張) | `run_ai_tick` とテストあり (`src/ai/contracts*.mbt`) | 部分 |
| Audio | `audio/*` | 対応モジュールなし | 未着手 |
| Mobile ターゲット | `mobile/*` | ターゲット/実装とも未着手 | 未着手 |
| Utility 系 (`vector`, `colorm`, `ebitenutil`, `inpututil`) | 各 package | `inpututil` 相当で key + mouse button の JustPressed/JustReleased/Duration/Append を実装。他は未着手 | 部分 |

## 優先 TODO (実装順)

### P0: まず「Web と Native 両方で実ゲーム描画」を成立させる

1. `gfx` draw command を Native 実 backend に接続する  
   - 現在は Native hook が `end(present)` 時に固定三角形を描くのみ。  
   - `DrawTrianglesCommand` を実際に反映する経路へ置き換える。
2. WebGPU 実装を `WebCanvasPlatform`/`gfx` hook 経由で接続する  
   - JS 側で canvas/context 取得、surface token 生成、begin/end/draw を本実装化。
3. WebGL2 フォールバック backend を追加する  
   - WebGPU 非対応環境向けに最低限の draw path を用意。
4. backend 共通の resize/reconfigure を追加する  
   - window/canvas サイズ変化時の surface 再構成を定義。
5. 同一ロジックの cross-backend 検証テストを追加する  
   - js/native で tick 数、終了条件、最小描画結果が一致することを確認。

### P1: Ebiten の中核描画機能へ寄せる

6. CommandQueue の merge 条件を実装する  
   - pipeline/texture/blend/uniform の互換条件で batch する。
7. `asset` の ImageRepository + AtlasAllocator を実装する  
   - managed/unmanaged、部分更新、解放戦略を定義。
8. Shader frontend を Kage/Ebiten 相当へ強化する  
   - source 前処理、source hash、uniform レイアウト整合を厳密化。
9. Uniform canonicalize を Ebiten 互換に近づける  
   - preserved uniforms と unused filtering の挙動を詰める。
10. Builtin shader (nearest/linear/pixelated + address mode) を実ソース化する  
   - lazy cache と cleanup 戦略を追加する。

### P1: 入力/実行系の基本互換

11. 入力 snapshot を実デバイス連動にする  
   - keyboard/cursor/wheel/mouse buttons は Web + Native で最小接続済み。gamepad は Web + Native で最小接続済み。  
   - native touch は Cocoa event からの取得を追加済み。gesture/trackpad 以外の環境では left-click fallback が残るため、実機差分を詰める。
12. `inpututil` 相当 API を追加する  
   - key + mouse button の差分 API は実装済み。  
   - touch/gamepad 向けの差分 API を追加する。
13. window/system API を本実装レベルに引き上げる  
   - fullscreen, cursor, monitor, deviceScale, vsync, close/requestAttention は契約 + 部分実装まで完了。  
   - GLFW / browser での edge-case（非同期 fullscreen 反映、pointer lock 状態同期、vsync 実反映）を詰める。

### P2: 周辺機能と拡張層

14. `text` に `mizchi/font` を接続し glyph cache + draw command 化する。
15. `ui` に `mizchi/layout` を接続し input/render bridge を実装する。
16. `ai.run_ai_tick` を `runtime.run_loop` に統合する  
   - budget、deterministic seed、trace を runtime から制御。
17. audio サブシステムを追加する  
   - PCM/stream/player、最低限 WAV/OGG 互換を目標。
18. utility レイヤーを追加する  
   - `vector`, `colorm`, `ebitenutil` 相当の薄い API を整備。
19. mobile ターゲット戦略を定義する  
   - iOS/Android は Web か Native どちらの backend を使うか確定する。

## 完了条件 (Ebiten 同等機能の第一段階)

- 2D 基本機能:
  - sprite 描画、offscreen 合成、shader、text、input が js/native で同一 API で動く
- backend:
  - WebGPU が第一実装、WebGL2 がフォールバック、Native wgpu が本実装
- 品質:
  - `moon check/test` (js/native) + Playwright e2e が常時通る
- 互換性:
  - `docs/ebiten_reference.md` の主要項目に対して `未着手` がない状態
