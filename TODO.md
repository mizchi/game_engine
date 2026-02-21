# TODO (Ebiten 同等機能ロードマップ)

このファイルは未完了タスクのみを管理する。
完了済みは `docs/mvp.md` の `DONE` セクションへ退避。

## ゴール再確認

- 目標: Ebiten と同等の 2D ゲームエンジン機能を MoonBit で提供する
- 優先: WebGPU (browser) と native wgpu (macOS) で同一ゲームロジックを早期に動かす
- 非目標: WebGL/WebGL2 フォールバック
- 3D 拡張は 2D API/実装安定後

## 実装状況スナップショット (2026-02-21)

- `moon test --target native`: 575 passed / 0 failed
- `moon test --target js`: 574 passed / 0 failed
- `moon run src/examples/runtime_smoke --target js`: pass
- `moon run src/examples/runtime_smoke_native --target native`: pass (hook_font_load + hook_font_load_full + hook_font_load_cjk + audio_smoke)
- `pnpm e2e:smoke`: 21 passed / 0 failed

## 現在の優先タスク (優先順位順)

(なし — MVP 第一段階の全タスク完了)

## 完了条件 (第一段階)

- 2D 基本機能（sprite/offscreen/shader/text/input）が js/native 同一 API で動作
- backend は WebGPU (browser) + native wgpu を維持
- `moon check/test` (js/native) + Playwright e2e が常時通る
- `docs/ebiten_reference.md` の主要項目に `未着手` がない

## 参照

- 完了済み一覧: `docs/mvp.md`
