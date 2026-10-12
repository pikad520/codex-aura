# Cross-platform release work

## Localization and 1.5 release

- [x] Add shared en/zh-CN/ja catalog, locale resolution and persistent language preference.
- [x] Localize both native hosts and add live language controls without changing animation state.
- [x] Localize installer and local management messages; keep system-language defaults.
- [x] Verify local locale migration, translated macOS controls and builds.
- [ ] Verify Windows native controls and all installer languages in CI.
- [ ] Update multilingual documentation, push, verify CI and publish the new release.

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
