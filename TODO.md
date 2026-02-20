# TODO (Ebiten 同等機能ロードマップ)

このファイルは未完了タスクのみを管理する。
完了済みは `docs/mvp.md` の `DONE` セクションへ退避。

## ゴール再確認

- 目標: Ebiten と同等の 2D ゲームエンジン機能を MoonBit で提供する
- 優先: WebGPU (browser) と native wgpu (macOS) で同一ゲームロジックを早期に動かす
- 非目標: WebGL/WebGL2 フォールバック
- 3D 拡張は 2D API/実装安定後

## 実装状況スナップショット (2026-02-21)

- `moon test --target native`: 554 passed / 0 failed
- `moon test --target js`: 553 passed / 0 failed
- `moon run src/examples/runtime_smoke --target js`: pass
- `moon run src/examples/runtime_smoke_native --target native`: pass
- `pnpm e2e:smoke`: 10 passed / 0 failed

## 現在の優先タスク (優先順位順)

### P1: 次に着手

3. text の未完了統合
   - 完了: `TextRenderer` 高レベル API（font + atlas + batch builder 統合）
   - 完了: `SimpleTextBatchBuilder` を使った文字列 -> draw command の E2E 統合
   - 完了: runtime smoke draw_plan を TextRenderer 経由に移行
   - 残課題: プラットフォーム hook 経由のフォントファイル動的ロード運用
   - 残課題: 複数グリフ・複数フォントサイズでの文字列ラスタライズ

4. audio backend 接続
   - 残課題: `AudioOutputHooks` を Web Audio API に接続
   - 残課題: `AudioOutputHooks` を native audio backend に接続

## 完了条件 (第一段階)

- 2D 基本機能（sprite/offscreen/shader/text/input）が js/native 同一 API で動作
- backend は WebGPU (browser) + native wgpu を維持
- `moon check/test` (js/native) + Playwright e2e が常時通る
- `docs/ebiten_reference.md` の主要項目に `未着手` がない

## 参照

- 完了済み一覧: `docs/mvp.md`
