# MoonBit project commands

target := "js"

default: check test

fmt:
    moon fmt
    for dir in examples/*/; do (cd "$dir" && moon fmt); done

check:
    moon check --deny-warn --target {{target}}
    for dir in examples/*/; do (cd "$dir" && moon check --deny-warn --target {{target}}); done

test:
    moon test --target {{target}}
    for dir in examples/*/; do (cd "$dir" && moon test --target {{target}}); done

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
