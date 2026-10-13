# Cross-platform release work

## Transparent player contrast

- [x] Register and reproduce REG-001 on a dark target with a light companion appearance; record user selection of dual-tone outlines.
- [x] Apply the selected style to symbols, time labels and sliders without changing the transparent/lower-layer behavior.
- [x] Verify the original regression threshold, light/dark appearance matrix, native playback/layout and full suite; install the signed build. Installed binary/resources match; settings and login preference unchanged; computer-use remains stopped.

## macOS transparent controls and click ripples

- [x] Add a passive native click observer and bounded ripple animation; verify coordinate/lifecycle/motion behavior.
- [x] Remove the player backdrop, place it below the character, and retain music/hair response when its controls are hidden.
- [x] Add localized menu toggles, verify native visuals and regressions, update notes and install the signed build. Installed binary/resources match; settings and login preference unchanged. Computer-use services remain stopped.

## macOS local music player

### Glass toolbar and folder playlists

- [x] Confirm top-level folder scanning, mixed-script sorting, loop/shuffle and history rules.
- [x] Extend the existing player with folder playlists, automatic advancement and navigation; verify real audio and failure behavior.
- [x] Replace the single-row bar with native glass, two rows and a right-third anchor; add the five-row scrolling playlist.
- [x] Verify three-language layouts and native actions, update usage/verification notes and install the signed macOS build. Installed binary/resources match the build; existing settings and login preference are unchanged.

- [x] Inspect the native host, renderer and tests; record scope in specs/macos-music.md.
- [x] Add a native local player and compact nonactivating toolbar with centered window tracking.
- [x] Connect bounded music strength to smooth, protected hair motion in the shared renderer.
- [x] Verify native playback/lifecycle/layout, renderer regressions and both characters' pixels.
- [x] Inspect the native controls, update multilingual usage/verification notes and build the signed app. Direct Codex UI automation is unavailable; limits are recorded in docs/verification.md.

## Localization and 1.5 release

- [x] Add shared en/zh-CN/ja catalog, locale resolution and persistent language preference.
- [x] Localize both native hosts and add live language controls without changing animation state.
- [x] Localize installer and local management messages; keep system-language defaults.
- [x] Verify local locale migration, translated macOS controls and builds.
- [x] Verify Windows native controls and all installer languages in CI: 38238024050.
- [x] Update multilingual documentation, push and verify CI.
- [x] Publish verified installer and checksum: [v1.5.0-preview.1](https://github.com/pikad520/codex-aura/releases/tag/v1.5.0-preview.1); uploaded SHA-256 matches CI artifact.

## Second character

- [x] Generate and inspect blue hime-cut open/closed-eye artwork; preserve original textures.
- [x] Add shared character selection, fitted motion and derived linework.
- [x] Add persisted selection to macOS and Windows controls.
- [x] Verify settings, switching, browser pixel checks and local packaging; update multilingual usage and asset credits.
- [x] Install locally and verify the native character picker preserves existing appearance settings.
- [x] Push and verify Windows native fixture/installer CI: 38234511474.

- [x] Inspect existing macOS host, shared renderer and distribution scripts.
- [x] Record scope and acceptance in specs/windows-x64.md.
- [x] Confirm the Windows hosting dependency with the user.
- [x] Implement Windows x64 window tracking, click-through overlay, tray and appearance controls.
- [x] Add Windows per-user installer and automated build/test workflow.
- [x] Update all documentation for macOS local builds and Windows installer distribution, including actual verification versions.
- [x] Verify macOS regressions, Windows compilation, native fixture and installer/uninstaller checks; record remaining manual coverage.
- [x] Push to GitHub and check workflow results; native animation/installer run: 38230748673.
- [x] Verify explicit native motion/reduced-motion coverage and retrieve the Windows installer; SHA-256 verified.
