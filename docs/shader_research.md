# Ebiten Shader Research Notes

`hajimehoshi/ebiten` の shader 実装を、`kagura` 契約へ写すための調査メモ。

## 1. Frontend -> IR 変換は 2 段に分離

- `internal/graphics/shader.go`
  - `completeShaderSource`: ユーザー shader に suffix を差し込み
  - `CompileShader`: `internal/shader.Compile` を呼んで `shaderir.Program` を作成
  - `CalcSourceHash`: 完成ソースの hash 計算
- `internal/shader/shader.go`
  - `//kage:unit` を解析
  - uniform 名を並べ替え（`__` 先頭を preserved として先頭に寄せる）

示唆:
- `kagura` でも
  - source 前処理
  - IR compile
  - source hash
  を API として分離する。

## 2. Uniform の正規化が command merge の前提

- `internal/ui/shader.go`
  - `AppendUniforms`: `map[string]any` を dword 配列に詰める
- `internal/graphicscommand/commandqueue.go`
  - `prependPreservedUniforms`: dst/src region などの preserved uniforms を先頭へ差し込む
  - その後 `FilterUniformVariables` を適用
- `internal/shaderir/program.go`
  - `FilterUniformVariables`: 到達不能 uniform を 0 化し merge 率を上げる

示唆:
- `uniform pack -> preserved prepend -> filter unused` を 1 セットとして契約化する。

## 3. Built-in shader は「テンプレ生成 + lazy cache + 遅延実体化」

- `internal/builtinshader/shader.go`
  - nearest/linear/pixelated + address mode + colorM で source テンプレ生成
- `shader.go`
  - public 側で built-in shader を lazy cache
- `internal/atlas/shader.go`
  - `graphicscommand.Shader` を遅延生成し、cleanup/deallocate を管理

示唆:
- `kagura` 初期段階は
  - `clear / nearest / linear`
  の built-in source 契約を先に固定する。

## 4. Backend 差分は shader adapter へ閉じ込める

- OpenGL: link 失敗時に compile log を集約 (`internal/graphicsdriver/opengl/shader.go`)
- Metal: `SourceHash` キーで precompiled library 利用 (`internal/graphicsdriver/metal/shader_darwin.go`)
- DirectX:
  - precompiled FXC + vertex shader cache
  - constant buffer packing
  - matrix transpose / projection Y 反転
  (`internal/graphicsdriver/directx/shader_windows.go`)

示唆:
- backend 実装で吸収する責務:
  - binary cache
  - uniform packing rule
  - matrix/座標系差分

## 5. 反映済みの契約アウトライン

- `src/gfx/shader_contracts.mbt`
  - `ShaderFrontend`
  - `UniformCanonicalizer`
  - `BuiltinShaderSourceRepo`
  - `ShaderIR`, `PackedUniforms`, `BuiltinShaderKey` などの stub 型
