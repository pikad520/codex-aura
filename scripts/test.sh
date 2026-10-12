#!/bin/zsh
set -eu
project_dir="$(cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$project_dir"
./build.sh
mkdir -p .build/tests
xcrun swiftc source/AppearanceSettings.swift tests/appearance-tests.swift -o .build/tests/appearance-tests
xcrun swiftc source/WindowPolicy.swift tests/policy-tests.swift -o .build/tests/policy-tests
.build/tests/appearance-tests
.build/tests/policy-tests
node tests/test-renderer.cjs
node tests/test-one-shot.cjs
python3 tests/test_installer.py
codesign --verify --deep --strict 'Codex Aura.app'
