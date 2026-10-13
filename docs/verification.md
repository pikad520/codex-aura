# Verification / 验证记录 / 検証記録

Recorded: 2026-10-12. Latest application version: 1.5.0. The initial baseline below is 1.3.0; later version checks follow.

| Environment | Exact version | Scope |
| --- | --- | --- |
| Local macOS | 26.5.1 (25F80), Apple Silicon arm64 | Local build, ad-hoc signature and existing automated regressions passed |
| Local Swift | Apple Swift 6.3.2 | macOS deployment target 12.0; Intel not tested |
| Local target desktop app | 26.1007.30912 (20156), `com.openai.codex` | Previous macOS overlay/control-panel verification; no new Codex UI automation |
| Local test tools | Node.js 22.22.3; Python 3.13.9 | Shared renderer and isolated macOS installer tests |
| Windows cross-compilation | .NET SDK 10.0.401; WebView2 SDK 1.0.4258.31; win-x64 | Release build with zero warnings/errors; self-contained publish; settings/window-policy tests passed |
| Windows CI | Windows Server 2025 Datacenter, build 26100, x64; .NET SDK 10.0.401 / runtime 10.0.12; WebView2 Runtime 153.0.4234.48; Inno Setup 6.7.1 | [Passed build, native animation/reduced-motion fixture and installer/uninstaller checks](https://github.com/pikad520/codex-aura/actions/runs/38230748673) |

The native fixture produced 37 frames and an advancing animation clock in the sampled motion-enabled state; all four appearance values reached the actual renderer. The test also confirmed a stopped clock while hidden and while reduced motion was enabled, translucent WPF composition, nonactivating/click-through window styles and matching physical bounds. The captured image had 569,698 rendered translucent pixels. This verifies native composition against our own test window, not actual input pass-through on Codex.

The project targets `net10.0-windows10.0.22000.0` so the Windows SDK projection assemblies needed by WebView2 composition are included. .NET SDK 10.0.401 is pinned by `global.json`. Subsequent checks and installer builds are in [Actions](https://github.com/pikad520/codex-aura/actions/workflows/verify.yml).

The minimum deployment target is not proof that every OS version is tested. Windows targets Windows 11 x64 (build 22000 or later). No Windows x86, ARM64, macOS Intel or Linux validation is claimed.

Windows automated native checks use an isolated fixture window, not an installed Codex app. They check real WebView2/WebGL readiness, appearance updates, rendered translucent WPF pixels, native click-through/nonactivation styles, physical window bounds and pause-on-hide. Installer tests check per-user installation, bundled resources, login startup off by default and uninstall. Foreground policy and settings persistence have separate automated tests.

Outstanding manual checks on Windows: real Codex.exe identity and window following, actual mouse/keyboard pass-through, mixed-DPI physical monitors, virtual desktops, fullscreen and GPU/performance behavior. No real Windows Codex version has been verified yet. Native fullscreen and physical multi-monitor transitions also remain unverified on macOS.

中文：构建成功、策略测试和测试窗口验证，不等于真实 Codex 使用验证。Windows 真实 Codex 版本、鼠标键盘穿透、多显示器与全屏仍待实机确认；macOS 的全屏与多显示器切换也未完整验证。

日本語：ビルド、ポリシーテスト、専用テストウィンドウの検証は、実際の Codex での動作確認とは異なります。Windows の実際の Codex バージョン、入力透過、複数画面、フルスクリーンは未検証です。macOS のフルスクリーンと複数画面の切り替えも未検証です。

## Second character (1.4.0)

Local macOS build/signature, Swift settings migration and character persistence, shared renderer switching/race/one-shot tests, Windows settings persistence and x64 cross-compilation passed on the same local environment above. All four original golden asset SHA-256 values match the previous commit. No dependency versions changed. The updated macOS app was installed locally; the native picker selected Blue · Hime cut and retained all four existing appearance values.

Real browser pixel checks ran in Chrome 154.0.8037.98 on macOS: the saved blue selection loaded first; full blink changed 23,203 pixels inside the eye region and zero outside it; hair motion changed 212,992 pixels with zero changes in the protected face region. Derived linework rendered, and open/half-closed/closed/linework frames were visually inspected. This is texture deformation, not a skeletal character model.

Optional reproduction, with Playwright and a local Chromium already available: `AURA_BROWSER_CHANNEL=chrome node tests/test-character-browser.cjs` (omit the environment variable for Playwright's own Chromium). This test starts an isolated loopback server and writes evidence only under `.build/character-check/`; Playwright is test tooling, not an application dependency. Normal app operation needs no HTTP server.

Windows CI additionally loads the blue character in the native WebView2 fixture, confirms switching preserves the completed introduction, and captures `blue-overlay.png`. Actual Windows Codex interaction and physical multi-monitor/fullscreen coverage remain unverified.

Both jobs passed in [CI run 38234511474](https://github.com/pikad520/codex-aura/actions/runs/38234511474) for implementation commit `ec632d7`. Windows built the 1.4.0 x64 installer, loaded both characters in its native fixture, captured the blue overlay, and passed installation/uninstallation checks. The installer is available as that run's `CodexAura-windows-x64-installer` artifact.

## Localization (1.5.0)

The shared catalog has complete English, Simplified Chinese and Japanese key coverage. Swift, .NET and Python locale tests cover first-launch system defaults, Chinese/Japanese regional variants, unsupported-language English fallback, explicit overrides and preference round trips. Existing renderer, character and installation regressions remain in the suite.

On macOS 26.5.1 arm64, first launch followed the actual Japanese OS language. The native panel was switched to English and Simplified Chinese and visually inspected; labels and actions fit, and the blue character and four appearance values were retained. App controls use the selected language; system-owned window chrome/dialogs and diagnostic error details may still use the OS language. No menu-dismissal fix is claimed by this release.

Windows CI now captures English/Chinese/Japanese native control panels, exercises selection without changing the character or appearance, and installs/uninstalls with each of the three installer languages. OS language matching is covered deterministically; CI does not change the runner's OS display language. Actual Windows Codex interaction, physical multi-monitor/fullscreen use and macOS Intel remain unverified.

Both jobs passed in [CI run 38238024050](https://github.com/pikad520/codex-aura/actions/runs/38238024050) for implementation commit `fa1c034`. Windows native evidence lists all three control languages; all three panel screenshots were visually inspected without clipped labels. English, Chinese and Japanese installer/uninstaller runs all passed, including bundled resources and startup disabled by default. The compiler was Inno Setup 6.7.1; official Chinese/Japanese messages are pinned in the repository because the runner omitted the optional Chinese language file. The existing native animation, character-switching and reduced-motion checks also passed. macOS manual language selection persisted across restart.

中文：1.5.0 的 macOS 与 Windows CI 均通过。Windows 三语原生面板截图检查、三语安装卸载检查通过；macOS 实测切换语言后保留参数，重启保留语言。实机覆盖限制仍如上所述。

日本語：1.5.0 の macOS・Windows CI は成功しました。Windows の 3 言語のネイティブ画面とインストール・削除を確認し、macOS では言語切り替え時の設定保持と再起動後の言語保持を確認しました。実機検証の制限は上記のとおりです。

## macOS local music (2026-10-13, local source build)

The signed macOS build and `./scripts/test.sh` passed on the local arm64 environment above, without compiler warnings. New native checks generate real stereo WAV audio and verify load/error preservation, playback/time advancement, actual quiet/loud metering, pause, seeking, volume/mute, natural end/replay and stop. Policy checks cover player centering, narrow-window titlebar clearance and negative display coordinates. Renderer checks cover bounded/invalid samples, attack/release smoothing, reset on hide and static Reduce Motion. Existing appearance, localization, installation, one-shot and character regressions passed. No dependencies or character assets changed; Windows has no player and its music input defaults to zero.

Chrome 154.0.8037.98 WebGL checks compare maximum music gain against ordinary hair motion at identical times (2, 4 and 6 seconds). Golden changes 510,984–521,075 pixels, blue 424,201–433,881; all three samples of both characters have **zero additional changed pixels** in the conservative face/ear and clothing regions. Maximum-gain frames were visually inspected. This measures the additional music deformation, not the original animation. Evidence is generated in `.build/music-check/` by `tests/test-music-browser.cjs`; reproduction uses the same optional Playwright setup as the character check above.

The independent native fixture (`tests/music-window-fixture.swift`) rendered English, Chinese and Japanese controls at 1200/350/300-point target widths, checked control bounds and nonactivating/non-key panel behavior, and produced wide/compact screenshots. With the generated `native-demo.wav` present, `--verify` also checks that hiding stops meter callbacks while playback continues, and showing resumes sampling. Native UI actions selected a real WAV, played it, sought to 35 seconds, changed volume, muted and paused. The final non-key version was rechecked for file selection, playback and seeking; its diagnostics recorded `isKey: false` with Codex still foreground after file selection. Empty and loaded states, English wide layout and Japanese compact layout were visually inspected.

The updated companion was installed locally, preserving appearance/language and existing login-startup preference. Direct Codex-main-window UI automation was rejected by the computer-use tool, so actual cross-window input pass-through, continuous dragging/resizing on Codex, physical monitors and fullscreen remain manual verification limits. The native fixture is not a substitute for that coverage. No new Windows native/installer CI or release is claimed.

中文：macOS 播放器、真实音频电平、原生控件与布局、隐藏后继续播放、渲染平滑及已有回归通过。两个角色的最大音乐增幅在三个时刻均未额外改变受保护的脸、耳朵和衣服像素。已本地更新；工具禁止直接操作 Codex 主窗口，其跨窗口点击、拖动缩放、多显示器和全屏仍待实机确认。

日本語：macOS のプレーヤー、実音声レベル、ネイティブ操作と配置、非表示中の再生継続、滑らかな髪の動きと既存テストを確認しました。両キャラクターの顔・耳・衣服の保護領域では、最大追加効果でも 3 時点すべてで追加の画素変化がありません。ローカル更新済みです。Codex 本体の直接操作はツールに拒否されたため、ウィンドウ間の入力、移動・リサイズ、複数画面と全画面は引き続き実機確認が必要です。

## macOS folder playlist and titlebar glass (2026-10-13, native fixture)

This record covers the folder/playlist extension to the preceding file-player check. Source inspection of `source/MusicWindow.swift` confirms genuine `NSGlassEffectView` regular material with Swift 6.2+ on macOS 26+, and an active behind-window `NSVisualEffectView` titlebar fallback. The non-key transparent panel has no shadow; it uses SF Symbols, system fonts and semantic AppKit colors. `source/WindowPolicy.swift` sets a 356 × 44-point maximum, centered at two-thirds of the tracked window and clamped within 12-point side margins; targets under 620 points receive a 48-point top offset. The upper row contains folder, playlist, loop/shuffle, previous, play/pause, next and volume; the lower row keeps both time labels around the thin progress control.

The final `./scripts/test.sh` passed a warning-free signed macOS build, Swift appearance/policy/music checks, shared renderer and one-shot checks, Python installer checks, localization checks and deep strict signature verification. The real-WAV regressions in `tests/music-tests.swift` passed top-level visible-audio filtering, mixed-script filename order, first-playable autoplay, ordered wrap/EOF, 20 shuffle transitions without immediate repeats, actual-history previous, current-song resume, failed replacement preservation and invalid candidate skipping. Folder autoplay starts the first playable sorted song even in shuffle mode. Shuffle also passed the sole-playable fallback with a corrupt other file and one-song EOF repeat. Canceling the native folder chooser leaves the current playback untouched in the source path.

The updated native fixture `--verify` passed English, Simplified Chinese and Japanese control bounds/non-key checks at target widths of 1200/350/300 points. For playlists of 1/5/11 songs in each language, it verified complete first and final rows and stable heading/content size after playback refresh. The popover uses a plain table, a 160-point five-row viewport and 320 × 204-point content size, with an explicit 18-point heading frame and 10-point top padding. These checks cover the earlier fifth-row and heading clipping findings; independent review marked both fixed and accepted the component within the native-capture scope.

Computer-use actions against our own native fixture opened a directory-only `NSOpenPanel`, selected a folder and autoplayed 11 ordered songs. The playlist scrollbar reached the final row; a single click on `09` switched songs and closed the popover. Shuffle next and history-based previous were also checked through the native controls. Four post-fix captures in `.impeccable/review/` were inspected: `player-wide.png`, `player-compact.png`, `playlist-first.png` and `playlist-last.png`. The first and last playlist captures show five complete rows, a stable heading, and the paused-current checkmark on `波` and final `09` respectively.

The isolated captures flatten the surrounding backdrop, so material evidence combines those captures with the native glass source; they do not establish full Codex-window compositing. Direct Codex-main-window automation was rejected by the computer-use tool. Live Codex embedding, actual cross-window input, continuous dragging/resizing, physical multi-monitor and fullscreen behavior remain outside this verification. The older-macOS fallback is source-inspected, not separately captured on an older OS. This extension leaves the shared renderer unchanged and retains the preceding protected face/ear/clothing pixel evidence. The earlier local installation above remains historical; installation of this folder extension is not claimed here. No additional Windows CI or release is claimed.

中文：文件夹过滤、混合文字排序、自动播放、循环、随机不连续重复、实际播放历史、失败替换保留及单首可播放回退通过。原生测试窗口三语及 1200/350/300 点宽度通过；1/5/11 首歌的首尾完整行和标题稳定通过，真实控件完成文件夹选择、滚动到底及单击切歌。玻璃由原生 AppKit 实现；真实 Codex 合成、输入、拖动缩放、多显示器与全屏覆盖仍有限。

日本語：フォルダーの抽出と混在文字の並び順、自動再生、ループ、連続重複のないシャッフル、実際の再生履歴、失敗時の保持、再生可能な 1 曲へのフォールバックを確認しました。専用ネイティブウィンドウの 3 言語・1200/350/300 ポイントと、1/5/11 曲で先頭・末尾の完全な行と見出しの安定を確認し、実際の操作でフォルダー選択、末尾へのスクロール、1 回のクリックによる曲変更も確認しました。ガラスは AppKit ネイティブ実装です。実際の Codex での合成、入力、移動・リサイズ、複数画面と全画面の検証範囲は引き続き限定されています。

## macOS transparent controls and click ripples (2026-10-13)

The user superseded the toolbar's glass material with a fully transparent background and confirmed its order below the character, above Codex. The updated native fixture passed all three languages at 1200/350/300-point target widths, a clear nonopaque/shadowless panel, no glass/visual-effect root, transparent corner pixels and a window level below the character. Native control renders were inspected at wide/compact widths; the preview PNGs composite the captured controls over a fixture background and are not live Codex screenshots. The earlier five-row playlist geometry tests still pass. Hiding only the controls preserved real audio time advancement and continued level callbacks; hiding the character still stopped those callbacks while audio continued.

`tests/ripple-tests.swift` passed passive monitor registration/repeated activation/removal, nil hit testing, bounded positions, Reduce Motion suppression, the eight-ring limit and cleanup on completion/disable. A real visible native test panel produced Core Animation presentation layers whose ring paths grew and opacity decreased; early/expanded layer renders were inspected. The production overlay remains non-key and `ignoresMouseEvents = true`. The observer uses only left-mouse-down copies, filters foreground Codex and window bounds, never reposts events, and is removed when disabled/hidden or Reduce Motion is enabled. [Apple's API contract](https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents%28matching%3Ahandler%3A%29) guarantees observation cannot modify or prevent delivery of the original event. Coordinate tests include a negative secondary display and invalid/outside points.

`tests/test-effects-menu.py` compiles the unchanged AppDelegate class with a test entry point and invokes its actual menu selectors: both toggles and state-preserving English/Chinese/Japanese refresh passed. Toggles apply to this run, matching the existing overlay toggle, without changing settings serialization. `./scripts/test.sh` passed the warning-free signed build, all new checks and existing appearance, music, renderer, one-shot, localization and installer regressions. No character renderer, textures, dependencies or Windows host behavior changed.

No computer-use service was restarted for these checks. Native fixtures and layer renders do not verify a physical click reaching Codex or full-window compositing, drag/resize, physical multi-monitor or fullscreen use. Those remain manual coverage limits. The reduced-motion branch is tested through the component input and inspected native setting/notification wiring; the user's system preference was not changed.

## Transparent music contrast regression (2026-10-13)

Result: fixed at Level A native-render carrier. `tests/regression/music-control-contrast/manifest.json` has one active case, REG-001 (integration), no pending or archived cases. The original test renders the actual transparent player with Aqua companion appearance onto a #1e1e1e target backdrop. Before the change it exited 1: both time labels had maximum contrast 1.2553:1 and zero pixels at 4.5:1. The same default fixture and unchanged acceptance threshold now exit 0: both labels have 140 pixels at or above 4.5:1 and maximum contrast 16.6712:1. Before/after JSON, renders and command records are retained under the feature's active directory.

Direct cause: label/tint colors resolved against the companion's own appearance while the transparent controls were displayed over another app's independently themed background. Removing glass exposed this mismatch; the earlier previews composited only onto the matching native window background, missing cross-theme contrast. The user selected the previewed white foreground with fine dark outlines. `source/MusicWindow.swift` now applies cached outlined SF Symbols, outlined attributed time text on value changes and outlined slider tracks/knobs, with subdued disabled states. The player retains no backdrop or panel shadow and its lower window level. No public identifier, settings format, theme permission or dependency changed.

Reproduction uses the compile/run command in the manifest; `./scripts/test.sh` also compiles and runs REG-001 with both companion appearances against both target backgrounds. All four combinations passed, including 64 qualifying text pixels and maximum 13.0795:1 in the light backdrop. Additional `--playing-demo` checks loaded only the generated local WAV with muted output, sought to 35 seconds and verified the updated 0:35/1:00 labels remained readable on dark/light backdrops. All test processes exited; generated evidence remains in the ignored `.build/music-contrast` directory, with no changes to the user's music files or OS theme.

The native fixture passed all three languages at 1200/350/300-point target widths, transparency/non-key/layer checks, complete playlist rows and hidden-controls audio-level continuation. This covers the toolbar's language, transport and hidden-state reuse paths; playlist popover semantic colors are unchanged. The full build/signature, audio, click ripple, menu, renderer, appearance, one-shot, installer and localization suite passed. Native dark/light renders were visually inspected without starting computer-use. These are component fixtures, not real Codex screenshots; physical multi-monitor/scale factors, full-window composition and actual Codex interaction retain the manual limits above.
