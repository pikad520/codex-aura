#!/bin/zsh
set -eu
project_dir="$(cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$project_dir"
./build.sh
mkdir -p .build/tests
xcrun swiftc source/Localization.swift source/AppearanceSettings.swift tests/appearance-tests.swift -o .build/tests/appearance-tests
xcrun swiftc source/WindowPolicy.swift tests/policy-tests.swift -o .build/tests/policy-tests
xcrun swiftc source/MusicPlayer.swift tests/music-tests.swift -framework AVFoundation -o .build/tests/music-tests
xcrun swiftc source/WindowPolicy.swift source/ClickRipple.swift tests/ripple-tests.swift -framework AppKit -framework QuartzCore -o .build/tests/ripple-tests
xcrun swiftc source/Localization.swift source/WindowPolicy.swift source/MusicPlayer.swift source/MusicPlaylist.swift source/MusicWindow.swift tests/regression/music-control-contrast/active/REG-001.swift -framework AppKit -framework AVFoundation -o .build/tests/music-contrast
.build/tests/appearance-tests
.build/tests/policy-tests
.build/tests/music-tests
.build/tests/ripple-tests
.build/tests/music-contrast
.build/tests/music-contrast --light-backdrop
.build/tests/music-contrast --dark-companion
.build/tests/music-contrast --dark-companion --light-backdrop
python3 tests/test-effects-menu.py
node tests/test-renderer.cjs
node tests/test-one-shot.cjs
python3 tests/test_installer.py
python3 tests/test-localization.py
codesign --verify --deep --strict 'Codex Aura.app'
