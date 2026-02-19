# TODO (Ebiten 同等機能ロードマップ)

## ゴール再確認

- 目標は「Ebiten と同等の 2D ゲームエンジン機能」を MoonBit で提供すること。
- 優先は「ブラウザ(WebGPU/WebGL) と Native(macOS wgpu) の両方で早期に同じゲームロジックを動かすこと」。
- 3D 拡張は 2D の API/実装が安定してから着手する。

## 実装状況スナップショット (2026-02-19)

- `moon test --target native`: 135 passed / 0 failed
- `moon test --target js`: 130 passed / 0 failed
- `moon run src/examples/runtime_smoke --target js`: pass (`runtime_smoke(js): ok (hooked)`)
- `moon run src/examples/runtime_smoke_native --target native`: pass (`runtime_smoke_native: ok (real)`)
- `pnpm e2e:smoke` (Playwright wasm/wasm-gc parity + native runtime smoke): 4 passed / 0 failed

判定基準:

- `完了`: 最小実行までつながっており、テスト/スモークで確認済み
- `部分`: 契約はあるが stub 最小実装、または本実装が未接続
- `未着手`: 契約や実装が不足

## Ebiten 機能群に対する実装状況

| 機能領域 | Ebiten 参照 | 現状 | 判定 |
|---|---|---|---|
| Game ループ契約 (`Game/Layout/Update/Draw`) | `run.go`, `gameforui.go` | `src/core/contracts.mbt`, `src/runtime/contracts.mbt` に契約と最小ループあり。`run_loop_with_hooks` で input 観測 callback を注入可能にし、web/native で観測 tick 一致テストを追加。`outside_size` 変化時に `GraphicsDriver.resize` を呼ぶ導線を追加 | 部分 |
| 固定 timestep 計画 | `internal/clock/clock.go`, `internal/ui/context.go` | `step_fixed_timestep` 実装 + 単体テストあり (`src/core/fixed_timestep*.mbt`) | 完了 |
| Platform 抽象 (Desktop) | `internal/ui/ui_glfw.go` | `DesktopGlfwPlatform` + hook 注入 (`src/platform/contracts.mbt`) | 部分 |
| Platform 抽象 (Web) | `internal/ui/ui_js.go` | `WebCanvasPlatform` + hook 注入 (`src/platform/contracts.mbt`) | 部分 |
| Window/System API (fullscreen/cursor/monitor/deviceScale/vsync/close) | `run.go`, `internal/ui/ui.go`, `internal/ui/ui_glfw.go` | `PlatformDriver` API + wbtest 契約固定。Desktop は runtime bridge 経由で GLFW(close/fullscreen/cursor/content-scale/attention) を部分接続、Web は js runtime hook で DOM(fullscreen/cursor/close/attention/dpr) を部分接続 | 部分 |
| Platform-Gfx 境界 (SurfaceToken) | `ui_glfw.go`, `ui_js.go` | `src/platform/surface_contracts.mbt` で token 化済み | 部分 |
| GraphicsDriver 抽象 | `internal/graphicsdriver/graphics.go` | begin/end/new_image/new_shader/draw_triangles に加えて resize 契約を追加。native/web hook へ resize 伝播を接続 | 部分 |
| Native backend (wgpu + GLFW) | graphics driver 実装群 | `src/gfx_wgpu_native` で三角形描画まで実装。draw command のメタデータ（drawCalls/pipeline/uniform/blend/dst/shader/index/region/payload-count）を runtime bridge に伝播済み。さらにフレーム内 draw command queue を導入し、コマンドごとの triangle payload（position/UV/uniform/src_image_id）を保持して 1 pass で staged 描画する経路を追加。payload 描画は vertex/index buffer（queue write + drawIndexed）と sampler/texture bind group（seed 由来の最小 texture sampling）を使う経路へ更新済み。payload shader/pipeline は Native 側で LRU キャッシュ（device+format+payload key）を持ち、再生成コストを抑制。texture/bind-group は `seed + generation + pipeline` をキーにした最小 LRU キャッシュへ拡張済み。`src_image_id -> 2x2 RGBA palette` registry（register/clear/debug）と `src_image_id -> width/height/RGBA8 pixels` staged upload registry（begin/set/end + patch + debug query）を追加。generation 差分時は texture を作り直すだけでなく、サイズ一致かつ dirty rect ありなら `wgpuQueueWriteTexture` の subresource 更新でキャッシュ texture を in-place 更新する経路を追加。`runtime_resize_surface` を追加し resize hook から surface 再構成できるようにした。`runtime_smoke_native` で実行確認 | 部分 |
| Web backend (WebGPU/WebGL) | JS backend 群 | hook 経由で canvas/context 初期化 + clear pass + drawCalls 分の三角形描画 + WebGPU→WebGL2 fallback まで接続。draw command のメタデータ（pipeline/uniform/blend/dst/shader/index/region/payload-count）に加えて、triangle payload（position/UV/uniform/src_image_id）を js/wasm host へ伝播済み。js 側の present はフレーム内 command queue を順に処理して payload の position/uniform 色を shader source に反映する最小描画経路へ更新（texture sample/頂点バッファ/本格 cache は未実装）。`web_runtime_hooks` に source image cache + generation/diff sync（register/patch）と debug query API を追加し、`runtime_smoke` で atlas page generation/pixel 更新（42/43/44）を検証。`runtime_smoke` wasm e2e で経路確認 | 部分 |
| CommandQueue 集約/flush | `internal/graphicscommand/commandqueue.go` | `SimpleCommandQueue` で pipeline/texture(src_image_ids)/blend/uniform(index+uniform dwords)/index offset 条件の merge を実装（explicit geometry payload は非merge） | 部分 |
| Image/Atlas 管理 | `internal/atlas/image.go` | `SimpleImageRepository`/`SimpleShaderRepository`/`SimpleMaterialRepository` と `SimpleAtlasAllocator` の最小実装を追加（高度な管理戦略は未実装）。image spec に 2x2 RGBA palette と任意 RGBA8 配列を保持できるよう拡張し、`image_id -> palette/pixels/generation` の export API (`SourceImageBinding`) を追加。`update_image_spec` で同サイズ更新時に generation を進め、RGBA8 差分から dirty rect を計算できるようにした。`list_dirty_source_image_bindings`/`clear_source_image_dirty_flags` を追加し、native/web hooks には `sync_dirty_source_images_from_repository` を追加。native は dirty rect が full でない更新で patch API を使うよう接続済み（web は契約のみ） | 部分 |
| 画像 codec (decode/encode/resize) | Ebiten外 (拡張) | `mizchi/image` を依存追加し、`asset` パッケージに `ImageSpec <-> mizchi/image.ImageData` 変換と PNG/BMP/JPEG decode+encode、resize API を統合。format auto判別(`detect_raster_image_format`) と dispatch API (`decode_image_spec_auto` / `encode_image_spec`) および repository 直結 helper (`create/update_*_from_raster_bytes`) を追加。`src/asset/image_codec_wbtest.mbt` で roundtrip/resize/format判別/dispatch/create-update helper を検証。`src/examples/image_codec_smoke` で js/native の実行確認を追加し、`runtime_smoke`/`runtime_smoke_native` でも source image/atlas 更新を raster helper 経路で検証 | 部分 |
| Shader Frontend/Hash | `internal/graphics/shader.go`, `internal/shader/shader.go` | source 前処理 + entrypoint/unit/src-image 含む hash を実装。`//kage:unit` directive（pixels/texels）の解釈を追加（Kage本体は未実装） | 部分 |
| Uniform 正規化 | `internal/ui/shader.go`, `internal/shaderir/program.go` | layout 長（preserved/user）正規化 + source の識別子境界に基づく unused uniform 0化を実装 | 部分 |
| Builtin shader source | `internal/builtinshader/shader.go` | filter/address/color_m 差分の WGSL source 生成 + lazy cache + clear/evict を実装 | 部分 |
| Input snapshot 一貫性 | `internal/inputstate/inputstate.go` | Platform hook から tick ごとに取得する経路を追加。Web(JS hooks) は cursor/wheel/pressed_keys/mouse buttons/touches/gamepads の最小実装、Native(GLFW hooks) は cursor/wheel/pressed_keys/mouse buttons + gamepads + Cocoa touch 取得（touch 無効環境では left-click fallback）まで接続済み | 部分 |
| 共通 2D payload decoder | `internal/graphicscommand/command.go` | `src/payload2d` に頂点/indices/uniform/src_image_id の decode 契約を分離。native hook に加え web/js/wasm hooks でも利用開始（後で独立 repo へ切り出し可能） | 部分 |
| Text rendering | `text/v2` | `src/text/contracts.mbt` 契約のみ | 未着手 |
| UI レイアウト統合 | Ebiten外 (拡張) | `src/ui/contracts.mbt` 契約のみ | 未着手 |
| AI tick 実行基盤 | Ebiten外 (拡張) | `run_ai_tick` とテストあり (`src/ai/contracts*.mbt`) | 部分 |
| Audio | `audio/*` | 対応モジュールなし | 未着手 |
| Mobile ターゲット | `mobile/*` | ターゲット/実装とも未着手 | 未着手 |
| Utility 系 (`vector`, `colorm`, `ebitenutil`, `inpututil`) | 各 package | `inpututil` 相当で key/mouse button/touch/gamepad の JustPressed/JustReleased/Duration/Append（id 単位）を実装。`runtime` 側に input edge observer を追加しループ観測へ接続可能にした。他は未着手 | 部分 |

## 優先 TODO (実装順)

### P0: まず「Web と Native 両方で実ゲーム描画」を成立させる

1. `gfx` draw command を Native 実 backend に接続する  
   - draw command メタデータ伝播 + triangle payload の staged 描画経路（複数 command/フレーム）までは接続済み。
   - payload 用の pipeline cache、vertex/index buffer 転送、最小 texture sampling + bind group は導入済み。
   - bind group の寿命管理と再利用戦略（LRU + clear 連動）は導入済み。  
   - `src_image_id` ごとの palette registry（2x2 RGBA）経由で texture を解決する最小 API は導入済み。  
   - `src_image_id` ごとの RGBA8 staged upload registry（width/height/pixels）経由で texture を解決する API は導入済み。  
   - `asset` 側の palette/rgba8 情報を native hook から registry へ同期する導線（bindings/repository）は導入済み。  
   - texture/bind-group cache key の更新世代対応と、Repository generation を使った native 同期の差分反映は導入済み。  
   - dirty rect を backend の subresource 更新へ接続済み（source image registry 経由、サイズ一致時）。
   - `asset` 層で Atlas allocator 統合 + atlas page 単位 dirty rect 管理を実装済み（`SimpleAtlasImageRepository`）。
   - runtime/native/web hooks に atlas page dirty binding 同期 API を追加済み（native 実 backend の smoke で検証）。
   - `asset.get_atlas_draw_source`（page id + uv）を追加し、`runtime_smoke_native` の draw command は atlas page ID 経由へ切替済み。
   - `draw2d` パッケージを追加し、atlas 前提の quad draw command builder を導入済み。
   - `sprite2d` パッケージを追加し、`atlas key -> DrawTrianglesCommand` の高レベル builder を導入済み。
   - `tilemap2d` パッケージを追加し、複数 tile spec から draw command 群を組み立てる builder を導入済み。
   - `tilemap2d` に tile index -> atlas key 解決テーブル、chunk 範囲更新、page 単位 batched command 構築 API を追加済み。
   - `tilemap2d` に可視範囲 culling（`estimate_visible_tile_chunk` / `clip_tile_chunks_to_visible`）と visible-aware dirty chunk 差分（`diff_visible_tile_index_chunks`）を追加済み。
   - `runtime_smoke`（js/native）と `runtime_smoke_native` の両方で `diff -> culling -> append_tile_indexed_dirty_chunk_batched_draw_commands` 経路を検証済み。
   - `runtime_smoke/draw_plan` を追加し、js/native で共有する draw command 構築ロジックを 1 箇所化。whitebox test で payload 形状を固定済み。
2. WebGPU 実装を `WebCanvasPlatform`/`gfx` hook 経由で接続する  
   - JS 側で canvas/context 取得、surface token 生成、begin/end/draw を本実装化。
3. WebGL2 フォールバック backend を追加する  
   - WebGPU 非対応環境向けに最低限の draw path を用意。
   - `e2e/runtime_smoke_wasm.spec.ts` に force-webgl fixture（wasm/wasm-gc）を追加し、fallback 指定時の起動経路を継続検証。
4. backend 共通の resize/reconfigure を追加する  
   - `GraphicsDriver.resize` + runtime からの呼び出し導線は追加済み。  
   - window/canvas サイズ変化時の surface 再構成は native/web の基礎 hook を接続済み。  
   - 実 backend ごとの最適化（不要 reconfigure 抑制・再作成コスト計測）は未実装。
5. 同一ロジックの cross-backend 検証テストを追加する  
   - `runtime/contracts_wbtest` に `run_loop termination and minimal render summary match between native and webgpu` を追加済み。`should_close` による終了条件、`run_loop_with_hooks` の tick 観測数、render pass の clear 有無・clear 色、`graphics.end(true)` の present が一致することを検証。
   - Playwright e2e に backend ピクセル比較（webgpu/webgl2, pixelmatch 許容差分）を追加済み。
   - Playwright e2e から `moon run ... --target native` を実行する native smoke を追加済み。`runtime_smoke_native_probe` 行で `tex_seed/source_gen/atlas_gen/atlas_rgb` の検証を追加。
   - 残タスク: 実 backend（native vs web）間の直接ピクセル同値比較を自動化する。

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
   - key/mouse button/touch/gamepad の差分 API は実装済み。  
   - runtime ループ側の利用導線（`run_loop_with_hooks` + input edge observer + 履歴保持）は追加済み。  
   - UI/デバッグ表示への接続は未実装。
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
