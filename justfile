# MoonBit project commands

target := "js"

default: check test

fmt:
    moon fmt
    for dir in examples/*/; do [ -f "$dir/moon.mod.json" ] && (cd "$dir" && moon fmt); done

check:
    moon check --deny-warn --target {{target}}
    for dir in examples/*/; do [ -f "$dir/moon.mod.json" ] && (cd "$dir" && moon check --deny-warn --target {{target}}); done

test:
    moon test --target {{target}}
    for dir in examples/*/; do [ -f "$dir/moon.mod.json" ] && (cd "$dir" && moon test --target {{target}}); done

test-update:
    moon test --update --target {{target}}

e2e-install:
    pnpm install
    pnpm e2e:install

e2e:
    pnpm e2e

e2e-smoke:
    pnpm e2e:smoke

info:
    moon info

dev name:
    bash scripts/dev.sh {{name}}

run-native name:
    cd examples/{{name}} && CPATH="$(brew --prefix glfw)/include:${CPATH:-}" LIBRARY_PATH="$(brew --prefix)/lib:${LIBRARY_PATH:-}" moon run src/ --target native

pages:
    bash scripts/build-pages.sh

check-release:
    @echo "Checking for local path dependencies..."
    @if grep -q '"path"' moon.mod.json; then echo "ERROR: moon.mod.json contains local path dependencies"; grep '"path"' moon.mod.json; exit 1; else echo "OK: No local path dependencies found"; fi
    moon check --target js
    moon check --target native

clean:
    moon clean
    for dir in examples/*/; do (cd "$dir" && moon clean); done

# WASM game host tasks
wasm-build-moonbit:
    cd examples/wasm_game/guest/moonbit && moon build --target wasm
    mkdir -p examples/wasm_game/host/public
    cp examples/wasm_game/guest/moonbit/_build/wasm/debug/build/wasm_game_guest.wasm examples/wasm_game/host/public/game.wasm

wasm-build-rust:
    cd examples/wasm_game/guest/rust && rustup run stable cargo build --target wasm32-unknown-unknown --release
    mkdir -p examples/wasm_game/host/public
    cp examples/wasm_game/guest/rust/target/wasm32-unknown-unknown/release/kagura_wasm_guest_rust.wasm examples/wasm_game/host/public/game.wasm

wasm-host-install:
    cd examples/wasm_game/host && pnpm install

wasm-test guest="all":
    node examples/wasm_game/test-wasm.mjs {{guest}}

wasm-dev guest="moonbit": (wasm-build guest)
    cd examples/wasm_game/host && pnpm dev

[private]
wasm-build guest:
    @if [ "{{guest}}" = "moonbit" ]; then just wasm-build-moonbit; elif [ "{{guest}}" = "rust" ]; then just wasm-build-rust; else echo "Unknown guest: {{guest}}"; exit 1; fi
