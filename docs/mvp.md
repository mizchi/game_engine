# MVP Progress (Ebiten 同等機能)

このドキュメントは、`TODO.md` から退避した完了済み項目の保管先。
`TODO.md` は未完了タスクのみを保持する。

## DONE

### 実行確認スナップショット (2026-02-21)

- `moon test --target native`: 575 passed / 0 failed
- `moon test --target js`: 574 passed / 0 failed
- `moon run src/examples/runtime_smoke --target js`: pass (`runtime_smoke(js): ok (hooked)`)
- `moon run src/examples/runtime_smoke_native --target native`: pass (hook_font_load + hook_font_load_full + hook_font_load_cjk + audio_smoke)
- `pnpm e2e:smoke`: 21 passed / 0 failed

### 機能領域 (判定: 完了)

- 固定 timestep 計画 (`step_fixed_timestep` + 単体テスト)
- CommandQueue 集約/flush（merge 条件 + explicit geometry merge + 上限）
- 画像 codec（PNG/BMP/JPEG decode/encode/resize + auto 判別 + repository helper）
- Shader frontend/hash（前処理、hash、`//kage:unit`、`//kage:noperspective`）
- Uniform 正規化（preserved/user layout 正規化 + unused 0 化 + f32 bit 変換）
- Builtin shader source（filter/address 差分 source + cache/evict + ClampToEdge + int roundtrip）
- 共通 2D payload decoder（`src/payload2d` 分離、native/web/js/wasm hooks 利用）
- AI tick 実行基盤（`run_ai_tick` + runtime hook 接続 + trace/history）
- SVG 描画（SVG -> RGBA、path 変換、stroke/fill 頂点化）
- Utility レイヤー（`vector`/`colorm`/`debugutil`/`inpututil`）

### 優先 TODO で完了済み (退避)

- P0-1: native 実 backend への draw command 接続（tile/sprite/text 3 command まで smoke 検証）
- P0-2: WebGPU 実装を `WebCanvasPlatform`/`gfx` hook 経由で接続
- P0-3: WebGL2 フォールバックは非目標として確定
- P0-4: backend 共通 resize/reconfigure + no-op 抑制 + stats
- P0-5: cross-backend parity/e2e/read_pixels 検証
- P1-6: CommandQueue merge 条件の実装
- P1-7: ImageRepository + AtlasAllocator（MultiPage/compact/stats）
- P1-8: Shader frontend 強化（validation/noperspective）
- P1-9: Uniform canonicalize 強化（validation + IEEE754）
- P1-10: Builtin shader 実ソース化（MirrorRepeat/extended cache）
- P1-12: `inpututil` 相当 API + runtime 導線
- P2-15: `ui` + `mizchi/layout` input/render bridge
- P2-16: `ai.run_ai_tick` の `runtime.run_loop` 統合
- P2-18: utility 拡張テスト一式
- P2-19: mobile ターゲット戦略を 2 段階で定義（Phase 1 Web、Phase 2 Native）
- P0-20: 入力 snapshot 実機差分（TouchSource enum + NSTouch type 区別 + mouse fallback opt-in）
- P0-21: window/system API 非同期状態同期（AsyncRequestStatus + fullscreen/pointer lock ポーリング）
- P1-3: FontLoadHooks（text パッケージ hook + native C FFI + Web JS/WASM bridge）
- P1-4: Audio Web Backend（Web Audio API ScriptProcessorNode + ring buffer, JS/WASM 両対応）
- P2-1: フォント動的ロード運用検証（hook 経由 E2E + 複数サイズ glyph cache + native smoke）
- P2-2: Native Audio Backend（miniaudio + ring buffer + MoonBit FFI bridge + native hooks 接続）
- P3-2: WASM Audio Backend 接続（WASM host extern 7関数 + font stub + runtime_smoke audio smoke E2E）
- P3-1: E2E テスト拡張（WASM font load 実装 + font smoke + native hook_font_load/audio_smoke アサーション, 16 tests）
- P3-3: 複数フォント・複数サイズ本格運用（full-set TTF multi-char measure + multi-size + missing glyph degradation + atlas stress, 18 e2e tests）
- P4-1: 日本語テキスト対応（CJK サブセットフォント + multi-page atlas + eviction + CJK E2E 検証, 21 e2e tests）

### 3D / Audio (2026-02-28)

- scene3d パッケージ抽出（`src/scene3d/`）— `scene3d()` ビルダー + `render_scene3d()` + CPU 側 3D→2D 投影
- arena3d オーディオ SE 対応（サイン波 PCM 生成、Web/Native 両方で動作確認）
- MixerAudioContext ボイスライフサイクル修正（create_player の GC 問題、play の状態遷移）
- arena3d 初期化バグ修正（platform.initialize / graphics.initialize 欠落）

## NOTE

- 現在進行中の項目は `TODO.md` を参照。
- 詳細な実装ログは Git 履歴を正とする。
