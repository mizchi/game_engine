# TODO (Ebiten 同等機能ロードマップ)

## ゴール再確認

- 目標は「Ebiten と同等の 2D ゲームエンジン機能」を MoonBit で提供すること。
- 優先は「ブラウザ(WebGPU) と Native(macOS wgpu) の両方で早期に同じゲームロジックを動かすこと」。
- 方針: WebGL/WebGL2 フォールバックは対応しない（非目標）。ブラウザ backend は WebGPU のみを対象とする。
- 3D 拡張は 2D の API/実装が安定してから着手する。

## 実装状況スナップショット (2026-02-20)

- `moon test --target native`: 510 passed / 0 failed
- `moon test --target js`: 502 passed / 0 failed
- `moon run src/examples/runtime_smoke --target js`: pass (`runtime_smoke(js): ok (hooked)`)
- `moon run src/examples/runtime_smoke_native --target native`: pass (`runtime_smoke_native: ok (real)`)
- `pnpm e2e:smoke` (Playwright wasm/wasm-gc parity + native runtime smoke + cross-backend probe parity + pixel capture + read_pixels probe + tile+sprite+text command_count=3): 8 passed / 0 failed

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
| GraphicsDriver 抽象 | `internal/graphicsdriver/graphics.go` | begin/end/new_image/new_shader/draw_triangles/resize/read_pixels 契約を実装。native/web hook へ resize/read_pixels 伝播を接続。`FramebufferSnapshot` 構造体を定義 | 部分 |
| Native backend (wgpu + GLFW) | graphics driver 実装群 | `src/gfx_wgpu_native` で三角形描画まで実装。draw command のメタデータ（drawCalls/pipeline/uniform/blend/dst/shader/index/region/payload-count）を runtime bridge に伝播済み。さらにフレーム内 draw command queue を導入し、コマンドごとの triangle payload（position/UV/uniform/src_image_id）を保持して 1 pass で staged 描画する経路を追加。payload 描画は vertex/index buffer（queue write + drawIndexed）と sampler/texture bind group（seed 由来の最小 texture sampling）を使う経路へ更新済み。payload shader/pipeline は Native 側で LRU キャッシュ（device+format+payload key）を持ち、再生成コストを抑制。texture/bind-group は `seed + generation + pipeline` をキーにした最小 LRU キャッシュへ拡張済み。`src_image_id -> 2x2 RGBA palette` registry（register/clear/debug）と `src_image_id -> width/height/RGBA8 pixels` staged upload registry（begin/set/end + patch + debug query）を追加。generation 差分時は texture を作り直すだけでなく、サイズ一致かつ dirty rect ありなら `wgpuQueueWriteTexture` の subresource 更新でキャッシュ texture を in-place 更新する経路を追加。`runtime_resize_surface` を追加し resize hook から surface 再構成できるようにした。`runtime_smoke_native` で実行確認 | 部分 |
| Web backend (WebGPU) | JS backend 群 | hook 経由で canvas/context 初期化 + clear pass + drawCalls 分の三角形描画を接続。draw command のメタデータ（pipeline/uniform/blend/dst/shader/index/region/payload-count）に加えて、triangle payload（position/UV/uniform/src_image_id）を js/wasm host へ伝播済み。js 側の present はフレーム内 command queue を順に処理して、texture sample + vertex/index/uniform buffer 描画と draw resource cache（buffer/bind group 再利用）を実装。`install`/`uninstall` と `runtime_smoke_loader` の `shutdown` で WebGPU resource cleanup（cached buffers/textures/default texture 解放）を接続し、wbtest で解放を固定。`web_runtime_hooks` に source image cache + generation/diff sync（register/patch）と debug query API を追加し、`runtime_smoke` で atlas page generation/pixel 更新（42/43/44）を検証。`runtime_smoke` wasm e2e で経路確認 | 部分 |
| CommandQueue 集約/flush | `internal/graphicscommand/commandqueue.go` | `SimpleCommandQueue` で pipeline/texture(src_image_ids)/blend/uniform(index+uniform dwords)/index offset 条件の merge を実装。explicit geometry コマンド同士の vertex_data/indices 結合（インデックスオフセット付き）に対応、16384 float 上限付き。region-only と explicit の混合は非 merge | 完了 |
| Image/Atlas 管理 | `internal/atlas/image.go` | `SimpleImageRepository`/`SimpleShaderRepository`/`SimpleMaterialRepository` と `SimpleAtlasAllocator` の最小実装を追加。image spec に 2x2 RGBA palette と任意 RGBA8 配列を保持できるよう拡張し、`image_id -> palette/pixels/generation` の export API (`SourceImageBinding`) を追加。`new_source_image_binding`/`new_source_image_dirty_rect` ファクトリを追加し外部パッケージから `SourceImageBinding` を構築可能に。`update_image_spec` で同サイズ更新時に generation を進め、RGBA8 差分から dirty rect を計算できるようにした。`list_dirty_source_image_bindings`/`clear_source_image_dirty_flags` を追加し、native/web hooks には `sync_dirty_source_images_from_repository` を追加。native は dirty rect が full でない更新で patch API を使うよう接続済み（web は契約のみ）。Atlas 解放戦略を追加: allocator 空間再利用（全解放時 cursor リセット）、`multi_page_compact`（空ページ除去）、利用統計 API（`AtlasPageStats`） | 部分 |
| 画像 codec (decode/encode/resize) | Ebiten外 (拡張) | `mizchi/image` を依存追加し、`asset` パッケージに `ImageSpec <-> mizchi/image.ImageData` 変換と PNG/BMP/JPEG decode+encode、resize API を統合。format auto判別(`detect_raster_image_format`) と dispatch API (`decode_image_spec_auto` / `encode_image_spec`) および repository 直結 helper (`create/update_*_from_raster_bytes`) を追加。`src/asset/image_codec_wbtest.mbt` で roundtrip/resize/format判別/dispatch/create-update helper を検証。`src/examples/image_codec_smoke` で js/native の実行確認を追加し、`runtime_smoke`/`runtime_smoke_native` でも source image/atlas 更新を raster helper 経路で検証 | 完了 |
| Shader Frontend/Hash | `internal/graphics/shader.go`, `internal/shader/shader.go` | source 前処理 + entrypoint/unit/src-image 含む hash を実装。`//kage:unit` directive（pixels/texels）の解釈を追加。`//kage:noperspective` directive 解析 + `ShaderIR.noperspective` フィールド追加。`default_shader_entrypoints()` 追加（Kage本体は未実装） | 完了 |
| Uniform 正規化 | `internal/ui/shader.go`, `internal/shaderir/program.go` | layout 長（preserved/user）正規化 + source の識別子境界に基づく unused uniform 0化を実装。Float/Floats の dword 変換を IEEE 754 f32 ビット表現に修正（`double_to_f32_bits`/`f32_bits_to_double`） | 完了 |
| Builtin shader source | `internal/builtinshader/shader.go` | filter/address/color_m 差分の WGSL source 生成 + lazy cache + clear/evict を実装。`ClampToEdge` address mode 追加。filter/address の int roundtrip 関数追加 | 完了 |
| Input snapshot 一貫性 | `internal/inputstate/inputstate.go` | Platform hook から tick ごとに取得する経路を追加。Web(JS hooks) は cursor/wheel/pressed_keys/mouse buttons/touches/gamepads の最小実装、Native(GLFW hooks) は cursor/wheel/pressed_keys/mouse buttons + gamepads + Cocoa touch 取得（touch 無効環境では left-click fallback）まで接続済み | 部分 |
| 共通 2D payload decoder | `internal/graphicscommand/command.go` | `src/payload2d` に頂点/indices/uniform/src_image_id の decode 契約を分離。native hook に加え web/js/wasm hooks でも利用開始（後で独立 repo へ切り出し可能） | 完了 |
| Text rendering | `text/v2` | `mizchi/font` を依存追加し `SimpleFontEngine`（measure/shape）+ `GlyphCache`（atlas 領域割当）+ `SimpleTextBatchBuilder`（glyph quad → draw command）を実装。`GlyphAtlas` のピクセルバッファを `SourceImageBinding` ファクトリ経由で GPU に同期する E2E パスを追加。`runtime_smoke`/`runtime_smoke_native` で tile+sprite+text の 3 draw command を web/native 両 backend で検証済み（`command_count=3`）。wbtest でキャッシュ割当・行折返し・バッチ生成を検証 | 部分 |
| UI レイアウト統合 | Ebiten外 (拡張) | `mizchi/layout` を依存追加し `UITree`（ノード木）+ `SimpleLayoutEngine`（Row/Column/Auto/Fixed/Percent/padding/gap）+ `SimpleUIInputAdapter`（InputSnapshot → UIEvent 差分変換）+ `SimpleUIRenderAdapter`（layout → draw command）を実装。wbtest で single/row/column/padding レイアウトと input/render adapter を検証 | 部分 |
| AI tick 実行基盤 | Ebiten外 (拡張) | `run_ai_tick` とテストあり (`src/ai/contracts*.mbt`)。`AIRuntimeState` + `create_ai_post_update_hook` で runtime ループの `on_post_update` に接続可能。wbtest で blackboard 蓄積・hook 経由の decision 追跡を検証 | 完了 |
| Audio | `audio/*` | `AudioFormat`/`AudioClip`/`PlayerState`/`PlayerId` + `AudioStream`/`AudioContext` trait を定義。`SimpleAudioContext` で create/play/pause/stop/volume/seek/dispose/tick（ループ対応）を実装。`mizchi/audio` を依存追加し WAV/OGG コーデック（`decode_wav_clip`/`decode_ogg_clip`/`decode_audio_clip_auto`）+ `MixerAudioContext`（real mixer wrapper）+ `audio_buffer_to_clip`/`clip_to_audio_buffer` 変換を実装。wbtest 16 テストで検証 | 部分 |
| SVG 描画 | Ebiten外 (拡張) | `mizchi/svg` を依存追加し `src/svg` に SVG → RGBA pixel 変換（`render_svg`/`render_svg_to_rgba`）+ SVG path → vector.Path 変換（`svg_path_to_vector_path`）+ SVG path → stroke/fill 頂点変換を実装。wbtest 9 テストで検証 | 完了 |
| Mobile ターゲット | `mobile/*` | 戦略定義済み: Phase 1 = Web/WASM (PWA/WebView)、Phase 2 = Native (Metal/Vulkan)。Phase 1 は現状の Web backend で動作可能 | 部分 |
| Utility 系 (`vector`, `colorm`, `debugutil`, `inpututil`) | 各 package | `inpututil` 相当で key/mouse button/touch/gamepad の JustPressed/JustReleased/Duration/Append（id 単位）を実装。`runtime` 側に input edge observer を追加しループ観測へ接続可能にした。`src/vector` に Vec2 + Path（moveTo/lineTo/quadTo/cubicTo/arcTo/close + flatten + stroke_path/fill_path）を追加。`src/colorm` に ColorM（5x4 行列）を追加。`src/debugutil` に color helpers + line/rect/fill + `build_input_debug_overlay`（crosshair/pressed keys/mouse buttons 表示）を追加。`src/ui` に `ui_events_from_input_edge`（inpututil edge → UIEvent 変換）を追加。全テスト付き | 完了 |

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
   - `sprite2d` API を smoke テストに統合。tile + sprite + text の 3 draw command / フレームを native/web 両 backend で検証済み（`command_count=3`）。
   - `text` パッケージの `GlyphAtlas` を `SourceImageBinding` ファクトリ経由で GPU テクスチャに同期する E2E パスを追加。NotoSans OTF サブセット（1364 bytes, 'I' のみ）を埋め込みフォント定数として使用し、`parse_font_bytes` → `rasterize_glyph`（CFF outline → SVG → pixel）→ 64x64 アトラスへの blit → GPU テクスチャ同期 → NDC 座標でテキストクアッド描画の実フォントラスタライズパイプラインを web/native smoke で検証済み。
2. WebGPU 実装を `WebCanvasPlatform`/`gfx` hook 経由で接続する  
   - JS 側で canvas/context 取得、surface token 生成、begin/end/draw を本実装化。
   - WebGPU present に draw resource cache（vertex/index/uniform buffer + bind group のフレーム跨ぎ再利用）を追加し、`hooks_js` wbtest で再利用を固定。`runtime_smoke_loader.js`（wasm host）にも同等の cache 戦略を反映。
   - `install`/`uninstall` 経路と wasm host `shutdown` に WebGPU resource cleanup を追加し、cached buffers/textures/default texture の解放を `hooks_js` wbtest で固定。
3. （非目標）WebGL2 フォールバック backend は実装しない  
   - ブラウザ backend は WebGPU のみを対象とする。
   - WebGPU 非対応環境のサポートはスコープ外とする。
4. backend 共通の resize/reconfigure を追加する  
   - `GraphicsDriver.resize` + runtime からの呼び出し導線は追加済み。  
   - window/canvas サイズ変化時の surface 再構成は native/web の基礎 hook を接続済み。  
   - 同一サイズ `resize` の no-op 抑制を `GraphicsDriver` で追加し、wbtest で native/web hook の再呼び出しが起きないことを固定。
   - `GraphicsResizeStats`（resize_count/suppressed_count/current_width/current_height/last_resize_duration_ms/total_resize_duration_ms）を `StubGraphicsDriver` に追加。`graphics_resize_stats()` アクセサで reconfigure 回数と no-op 抑制回数を可視化。注入可能な `graphics_clock_provider` で wall-clock 計測に対応（`set_graphics_clock_provider`/`reset_graphics_clock_provider`）。wbtest 7 テスト追加（基本追跡 + duration 計測 + suppressed タイミング不変 + デフォルト clock）。
5. 同一ロジックの cross-backend 検証テストを追加する  
   - `runtime/contracts_wbtest` に `run_loop termination and minimal render summary match between native and webgpu` を追加済み。`should_close` による終了条件、`run_loop_with_hooks` の tick 観測数、render pass の clear 有無・clear 色、`graphics.end(true)` の present が一致することを検証。
   - Playwright e2e に backend ピクセル比較（webgpu, pixelmatch 許容差分）を追加済み。
   - Playwright e2e から `moon run ... --target native` を実行する native smoke を追加済み。`runtime_smoke_native_probe` 行で `tex_seed/source_gen/atlas_gen/atlas_rgb` の検証を追加。
   - `runtime_smoke`(web) の `runtime_smoke_web_probe` と `runtime_smoke_native_probe` を照合する cross-backend parity e2e を追加。`atlas generation/rgb` に加えて、triangle 内部サンプル（`sample0/1/2`）の予測 RGBA 一致と、サンプル座標差分（<= 12px）を検証。
   - `GraphicsDriver.read_pixels` 契約を追加。native/web hook に `on_read_pixels` を追加し、StubGraphicsDriver で境界チェック（未初期化/out-of-bounds/clamp）付き実装。wbtest 5 テスト追加。
   - `FramebufferSnapshot` + `create_framebuffer_snapshot`/`compare_framebuffer_snapshots`/`pixel_diff_ratio` ピクセル比較ユーティリティを追加。wbtest 6 テスト追加（snapshot 作成/None ケース/同一ピクセル/threshold/サイズ不一致/ratio 計算）。
   - Playwright e2e に web ピクセルバッファ次元検証テストを追加（headless モードではキャンバスキャプチャが全ゼロになる制限を考慮）。6 passed。
   - 実 backend の `on_read_pixels` フック実装完了: native wgpu は staging buffer readback（BGRA→RGBA swizzle、同一 encoder encode_copy + map_and_read 2 phase）、web は per-channel scalar FFI（host_gfx_read_pixels_begin/channel/end）+ drawImage readback で接続。headless Chromium は SwiftShader（`--enable-unsafe-swiftshader --use-gl=swiftshader`）で実行し、native/web 両方で `read_pixels_len=64` を e2e 検証済み。

### P1: Ebiten の中核描画機能へ寄せる

6. CommandQueue の merge 条件を実装する
   - pipeline/texture/blend/uniform の互換条件で batch する。
   - `BlendFactor`/`BlendOperation`/`BlendEquation` を追加し `BlendMode::Custom(BlendEquation)` で任意のブレンド式を指定可能に。preset（Copy/Alpha/Add/Multiply）は `blend_mode_to_equation` で展開可能。`blend_mode_eq` は Custom 同士の全 6 フィールド比較に対応。wbtest で roundtrip/equality/merge 非互換を検証。
   - explicit geometry コマンド同士の merge を実装: 同一レンダリング状態（dst/shader/blend/pipeline/uniforms/src_image_ids）を持つコマンドの vertex_data 結合 + indices オフセット付き結合。`max_merge_vertex_floats = 16384`（1024 quads）のバジェット制限。region-only と explicit の混合は非 merge。wbtest 6 テスト追加。
7. `asset` の ImageRepository + AtlasAllocator を実装する
   - managed/unmanaged、部分更新、解放戦略を定義。
   - `MultiPageAtlasRepository` を追加。ページ満杯時に自動で新ページを生成し、key → page ルーティングで cross-page query（draw source/region/update/remove）と dirty binding 集約を実装。wbtest 11 テストで検証。
   - Atlas 解放戦略を追加: `atlas_allocator_reset_if_empty`（全 region 解放後に cursor リセットで空間再利用）、`multi_page_compact`（空ページ除去 + key_page_index 再構築）、`AtlasPageStats`/`atlas_page_stats`/`multi_page_stats`（利用統計 API）。`remove_atlas_image` で自動リセットを接続。wbtest 8 テスト追加。
8. Shader frontend を Kage/Ebiten 相当へ強化する
   - source 前処理、source hash、uniform レイアウト整合を厳密化。
   - `validate_shader_compile_request`（empty source/entrypoints/negative src_image_count チェック）、`shader_unit_eq`、`shader_hash_eq` を追加。wbtest 7 テスト追加。
   - `default_shader_entrypoints()`（vertex="vs_main", fragment="fs_main"）を追加。`ShaderIR` に `noperspective : Bool` フィールドを追加し、`parse_kage_noperspective_directive` で `//kage:noperspective` directive を解析、`compile_ir` で ShaderIR に設定。wbtest 2 テスト追加。
9. Uniform canonicalize を Ebiten 互換に近づける
   - preserved uniforms と unused filtering の挙動を詰める。
   - `validate_uniform_layout`（重複名/負 dword_counts/mismatched lengths チェック）、`compute_expected_preserved_dwords`（Ebiten layout: dst_size+dst_region+per_src*(size+region)）、`validate_preserved_uniform_context`（src arrays 不整合/zero dst_size チェック）を追加。wbtest 9 テスト追加。
   - `double_to_f32_bits`/`f32_bits_to_double`（IEEE 754 f64→f32 ビット変換）を追加。`uniform_to_dwords` の `Float`/`Floats` を truncation(`v.to_int()`) から f32 ビット表現(`double_to_f32_bits(v)`) に修正し精度損失を解消。wbtest 4 テスト追加。
10. Builtin shader (nearest/linear/pixelated + address mode) を実ソース化する
   - lazy cache と cleanup 戦略を追加する。
   - `MirrorRepeat` address mode を追加。`SamplerSpec`（per-axis address_u/address_v）+ `BuiltinShaderKeyEx` で軸独立サンプラーを定義。`build_builtin_shader_source_ex` で per-axis address snippet 生成。wbtest 10 テスト追加。
   - `BuiltinShaderSourceRepo` に `shader_source_ex` を追加し、`BuiltinShaderKeyEx` 対応の extended cache を実装。classic/extended 混在 LRU eviction、cache hit/miss stats（`builtin_shader_cache_stats`）を追加。wbtest 5 テスト追加。
   - `ClampToEdge` address mode を追加（atlas 境界用）。tag/snippet/single_axis_address_expr/eq の全 match 式を更新。`builtin_filter_to_int`/`from_int`、`builtin_address_to_int`/`from_int` の int roundtrip 関数を追加。wbtest 4 テスト追加。

### P1: 入力/実行系の基本互換

11. 入力 snapshot を実デバイス連動にする
   - keyboard/cursor/wheel/mouse buttons は Web + Native で最小接続済み。gamepad は Web + Native で最小接続済み。
   - native touch は Cocoa event からの取得を追加済み。gesture/trackpad 以外の環境では left-click fallback が残るため、実機差分を詰める。
   - 契約テストを追加: 負カーソル座標、大 wheel 値、10 同時タッチ、4 ゲームパッド並列、ボタン 20 個、touch ID=0 境界、重複 ID 重複排除、rapid press/release/repress サイクル、step_fixed_timestep max_updates_per_frame キャップ。wbtest 13 テスト追加（core 7 + inpututil 6）。
   - `TouchPhase` enum（Began/Moved/Stationary/Ended/Cancelled）+ `TouchPointEx`（phase/pressure/delta_x/delta_y）を追加。`touch_phase_to_int`/`touch_phase_from_int` 変換 + `touch_point_from_ex` 互換変換。wbtest 3 テスト追加。
12. `inpututil` 相当 API を追加する
   - key/mouse button/touch/gamepad の差分 API は実装済み。
   - runtime ループ側の利用導線（`run_loop_with_hooks` + input edge observer + 履歴保持）は追加済み。
   - `ui.ui_events_from_input_edge` で inpututil edge → UIEvent 変換を実装済み。
   - `debugutil.build_input_debug_overlay` でカーソル crosshair + pressed keys/mouse buttons のデバッグ表示を実装済み。
   - gamepad button count API、ID=0 ゲームパッド動作、マルチゲームパッド独立追跡の契約テストを追加。
13. window/system API を本実装レベルに引き上げる
   - fullscreen, cursor, monitor, deviceScale, vsync, close/requestAttention は契約 + 部分実装まで完了。
   - GLFW / browser での edge-case（非同期 fullscreen 反映、pointer lock 状態同期、vsync 実反映）を詰める。
   - 契約テストを追加: fullscreen toggle cycle（冪等性）、cursor mode 全遷移パス、複数 capture_input tick 独立性、web device scale factor 境界値、web surface token 初期化。wbtest 5 テスト追加。
   - `FullscreenMode` enum（Windowed/Borderless/Exclusive）+ int 変換を追加。`MonitorInfo` に `refresh_rate_hz` フィールドを追加。wbtest 3 テスト追加（fullscreen mode roundtrip + desktop/web monitor refresh rate）。

### P2: 周辺機能と拡張層

14. `text` に `mizchi/font` を接続し glyph cache + draw command 化する。
   - `SimpleFontEngine`（TTFont wrapper）、`GlyphCache`（atlas 割当）、`SimpleTextBatchBuilder`（draw command 生成）を実装済み。
   - `GlyphAtlas`（cache + pixel buffer 統合）、`rasterize_glyph`（scaled_outline → SVG → pixel）、`rasterize_text`（文字列 → atlas glyph quads）、`blit_to_atlas`（pixel copy）を実装済み。wbtest 21 テストで検証。
   - 追加テスト: cache clear/re-allocate、page_id 伝播、blit_to_atlas 境界安全性、atlas ピクセルバッファゼロ初期化、空 path_commands_to_svg_d、zero-size text_style。
   - `GlyphAtlas` → GPU テクスチャ同期を `SourceImageBinding` ファクトリ経由で接続済み。`runtime_smoke`/`runtime_smoke_native` で tile+sprite+text の 3 draw command を検証。
   - NotoSans OTF サブセット（1364 bytes, 'I' のみ）を埋め込みフォント定数として使用し、`parse_font_bytes` → `rasterize_glyph`（CFF outline → SVG → pixel）→ 64x64 アトラス → GPU テクスチャ同期の実フォントラスタライズパイプラインを web/native smoke で検証済み。
   - スコープ外: KAGE 言語対応（シェーダーフロントエンド）、WebGL/WebGL2 backend でのテキスト描画（非目標）。
   - 残タスク: プラットフォーム hook 経由のフォントファイル動的ロード（`parse_font_bytes`/`load_font_engine_from_bytes` は追加済み）。複数グリフ・複数フォントサイズでの文字列ラスタライズ。`SimpleTextBatchBuilder` を使った文字列 → draw command の E2E 統合。
15. `ui` に `mizchi/layout` を接続し input/render bridge を実装する。
   - `UITree` + `SimpleLayoutEngine`（Row/Column 方向、Auto/Fixed/Percent サイジング、padding/gap）を実装済み。
   - `SimpleUIInputAdapter`（InputSnapshot → UIEvent 差分）+ `SimpleUIRenderAdapter`（layout → draw command）を実装済み。
   - `point_in_rect`/`hit_test`/`hit_test_all` によるヒットテストを実装済み。
   - `UIFocusManager`（focus/blur/focus_next/focus_prev/handle_pointer_down）によるフォーカス管理を実装済み。
   - `ui_events_from_input_edge` で inpututil edge → UIEvent 変換を実装済み。
   - `UIFlexWrap`（NoWrap/Wrap）+ `justify_content`/`align`（align-items）を `UINodeStyle` に追加。`SimpleLayoutEngine` で `@layout.compute_justify`/`compute_align_offset` を活用した flex line 分割・主軸配分・交差軸整列を実装。wbtest 38 テストで検証。
   - 追加テスト (+11): UIFocusManager focus_next/prev empty list、non-focusable ポインタ操作、hit_test 空配列・境界値・zero-size rect・負座標、Percent sizing、asymmetric padding、UITree 不在ノード取得、同時ボタン/キー、RenderAdapter 複数ノード、SpaceAround。
16. `ai.run_ai_tick` を `runtime.run_loop` に統合する
   - `AIRuntimeConfig`（enabled/global_budget/base_seed/trace_enabled/max_trace_history）で runtime からの制御を実装。`create_ai_post_update_hook` を config 対応に拡張。tick 単位の trace 蓄積・query（`get_traces_for_tick`/`get_recent_trace_ticks`）・history trimming を追加。wbtest 18 テストで検証。
   - 追加テスト: blackboard 永続化（agent 間共有）、odd tick 単一 agent、default budget/config 値、disable→re-enable 復帰、budget override、trace toggle、unknown tick traces。
17. audio サブシステムを追加する
   - `SimpleAudioContext`（PCM ベース契約テスト用）+ `MixerAudioContext`（mizchi/audio Mixer wrapper）を実装済み。
   - `mizchi/audio` の WAV/OGG コーデックを統合し `decode_wav_clip`/`decode_ogg_clip`/`decode_audio_clip_auto` を追加済み。
   - `AudioClipStream`（clip → sequential read）+ `BufferedAudioStream`（chunk-based progressive streaming）を実装。wbtest 28 テストで検証。
   - 追加テスト: 複数プレイヤー同時管理、seek リセット、zero-byte read、clip_to_audio_buffer フレーム数、mono_format 構築。
   - `AudioOutputHooks` 構造体（try_initialize/write_frames/suspend/resume/close/output_latency）を追加。`set_audio_output_hooks`/`reset_audio_output_hooks` + dispatch 関数（`audio_try_initialize`/`audio_write_frames`/`audio_suspend`/`audio_resume`/`audio_close`/`audio_output_latency`）を実装。`AudioOutputStats` 構造体を定義。wbtest 3 テスト追加（hook set/reset、default 動作、latency override）。
   - 残タスク: Web Audio API / native audio backend への AudioOutputHooks 接続。
18. utility レイヤーを追加する
   - `src/vector`（Vec2 2D ベクトル数学 + Path ベースの弧/ベジェ曲線描画）、`src/colorm`（ColorM 5x4 カラー行列）、`src/debugutil`（色ヘルパー + 線/矩形 draw command builder + input debug overlay）を実装済み。
   - colorm 追加テスト (+6): concat 結合律、double invert = identity、scale by zero、extreme translate clamp、no-op scale identity、monochrome→invert 合成。
   - debugutil 追加テスト (+4): hex 境界値、vertical/diagonal line、zero-size rect fill。
   - vector 追加テスト (+9): Vec2 div、perpendicular 直交性、normalize 方向保存、reflect 入射角保存、360° 回転、empty path、empty stroke、pentagon fill、close セマンティクス。
   - draw2d 追加テスト (+3): pipeline/blend 伝播、大座標、反転バウンズ。
   - sprite2d 追加テスト (+3): 空 uniform、全未解決キー、index_offset 伝播。
   - payload2d 追加テスト (+6): explicit indices、同一頂点 indices、xy-only with indices、複数 src_image_ids、uniform チャネル精度、clamp_unit 極値。
   - image_palette 追加テスト (+6): clamp_channel 境界値、rgba 全ゼロ/全最大、seed=0/大値、全ピクセル×全チャネル。
   - svg 追加テスト (+4): smooth cubic (S コマンド)、h/v 相対コマンド、fill 四角形、stroke 単一線分。
19. mobile ターゲット戦略を定義する
   - iOS/Android は Web か Native どちらの backend を使うか確定する。

   **戦略決定: 2 段階アプローチ**

   **Phase 1（短期）: Web/WASM ベース（PWA / WebView）**
   - 既存の `js`/`wasm`/`wasm-gc` ターゲット + WebGPU backend をそのまま利用。
   - iOS Safari / Android Chrome の WebGPU 対応環境で動作。
   - 追加実装コスト最小。PWA として配布、または Capacitor/TWA 等で WebView ラッパーを作成。
   - タッチ入力は `InputSnapshot.touches` で既に対応済み（10 同時タッチテスト済み）。
   - 制約: WebView パフォーマンス上限、ネイティブ API 非アクセス（加速度センサ等）。

   **Phase 2（中長期）: Native ビルド（iOS Metal / Android Vulkan）**
   - MoonBit `native` ターゲット (LLVM) で iOS arm64 / Android arm64 バイナリを生成。
   - wgpu は Metal (iOS) と Vulkan (Android) を既にサポートしており、`WgpuNative` backend を流用可能。
   - ウィンドウ管理: GLFW → 各 OS のネイティブウィンドウ API に差し替え（UIKit / Android Activity）。
   - 必要な拡張:
     - `PlatformDriver` にライフサイクル hook 追加: `on_pause()`, `on_resume()`, `on_destroy()`
     - `SurfaceKind` に `Vulkan` variant 追加（Metal は既存）
     - `InputSnapshot` に orientation / accelerometer / gyroscope 拡張（GamepadSnapshot パターン流用）
     - ソフトキーボード検出、immersive mode 対応
   - 前提: MoonBit native ターゲットの iOS/Android クロスコンパイル対応が安定すること。

   **現在のアーキテクチャ適合度**
   - trait ベースの `PlatformDriver`/`GraphicsDriver`/`SurfaceProvider` 分離により、新プラットフォーム追加は hook 実装のみ。
   - `InputSnapshot` にタッチ + ゲームパッドが既にモデル化済み。
   - hook injection パターンにより、モバイル固有の native 呼び出しを既存テストに影響なく追加可能。
   - `SurfaceToken` がプラットフォーム-グラフィックス境界を抽象化済み。

   **即座のアクション不要** — Phase 1 は現状の Web backend で既にモバイルブラウザ動作可能。Phase 2 は P0/P1 の描画パイプライン安定後に着手。

## 完了条件 (Ebiten 同等機能の第一段階)

- 2D 基本機能:
  - sprite 描画、offscreen 合成、shader、text、input が js/native で同一 API で動く
- backend:
  - WebGPU がブラウザ唯一実装、Native wgpu が本実装
- 品質:
  - `moon check/test` (js/native) + Playwright e2e が常時通る
- 互換性:
  - `docs/ebiten_reference.md` の主要項目に対して `未着手` がない状態
