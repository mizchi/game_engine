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

pages:
    bash scripts/build-pages.sh

clean:
    moon clean
    for dir in examples/*/; do (cd "$dir" && moon clean); done
