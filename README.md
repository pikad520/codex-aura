# Codex Aura

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md)

A click-through anime overlay for Codex, with blinking eyes, flowing hair and live appearance controls. macOS is built locally from source; Windows provides an x64 installer.

An independent, unofficial companion; it does not modify Codex or read chat content. Four original textures drive a shared Canvas/WebGL animation. The intro reveals line art into color once per launch; blinking and hair motion continue until hidden. It follows foreground app state, not actual model activity or loading progress.

## Supported distribution

| Platform | Distribution | Status |
| --- | --- | --- |
| macOS | Source; compile and sign locally | Apple Silicon verified; Intel not verified |
| Windows 11 x64 | `CodexAura-1.3.0-windows-x64-setup.exe` | Preview; see [verification](docs/verification.md) |

No macOS ZIP/DMG, Windows portable ZIP, x86 or ARM64 installer is provided. The macOS UI is Chinese; Windows controls are English. Documentation is available in all three languages.

## macOS: local build and local signature

Install Xcode Command Line Tools with Swift 5.7 or later, then build on your own Mac:

```sh
xcode-select --install  # Only if developer tools are missing.
git clone https://github.com/pikad520/codex-aura.git
cd codex-aura
./build.sh
codesign --verify --deep --strict 'Codex Aura.app'
open 'Codex Aura.app'
```

No paid Apple Developer account, Developer ID certificate, signing environment variable or API key is required. `build.sh` uses `codesign --force --sign -` for an **ad-hoc local signature**. It checks integrity but does not establish a trusted publisher identity or perform Apple notarization. This is a local-build workflow; redistributing the resulting app can trigger Gatekeeper. Rebuild after editing bundled files. See [Apple's signing documentation](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/) for distribution signing.

The script builds the current machine's architecture with macOS 12.0 as the deployment target. Actual local verification: **macOS 26.5.1 (25F80), arm64, Swift 6.3.2**, target app **26.1007.30912 (20156)** with bundle ID `com.openai.codex`. Other app IDs are not automatically supported. A deployment target is not a claim that every OS version has been tested.

You can drag the generated app to Applications. Alternatively, use Python 3 to install to `~/Applications/Codex Aura.app`:

```sh
python3 manage.py install
# Optional, after script installation:
python3 manage.py enable-login
```

The Finder launchers `安装并启动.command` and `开启登录自启.command` use `/usr/bin/python3`; CLI commands use `python3` on PATH. Python is not needed to run the app. Installation does not newly enable startup; updates preserve a previous explicit opt-in.

## Windows: x64 installer

Download the x64 Setup executable from [Releases](https://github.com/pikad520/codex-aura/releases). Development builds are also available as installer artifacts from [GitHub Actions](https://github.com/pikad520/codex-aura/actions/workflows/verify.yml) (sign-in may be required). The Actions download container contains the installer and SHA-256 checksum, not a portable distribution.

Requirements: **Windows 11 x64**, build 22000 or newer, and [Microsoft Edge WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/). If Runtime is missing, setup offers to open Microsoft's download page; install it and rerun setup. Setup does not silently download it. The app includes its .NET runtime; users do not need the .NET SDK, Python or Node.js.

Run Setup to install under `%LOCALAPPDATA%\Programs\Codex Aura`, without administrator privileges. Login startup and a desktop shortcut are optional and off by default. Launch from Start, then open Codex. The host currently matches the foreground process named **`Codex.exe`**, case-insensitively, rather than the window title. Other executable names are not automatically supported.

The installer is currently **unsigned**; Windows may show an unknown-publisher/SmartScreen warning or block it under system policy. Verify the source and checksum before use. Windows real-Codex end-to-end validation is still pending; the verification record distinguishes native fixture tests from actual app compatibility.

## Controls and behavior

Use the sun icon in the macOS menu bar or Windows notification area. Choose **调色控制面板… / Appearance…**; sliders and numeric fields update immediately and save automatically. On macOS, controls appear on first launch; on Windows, open them from the tray or double-click the tray icon.

| Setting | Default | Range |
| --- | --- | --- |
| Actual opacity | 20% | 0–100% |
| Saturation | 1.30× | 0–2× |
| Contrast | 1.10× | 0.5–2× |
| Brightness | 0.70× | 0.2–1.5× |

Restore defaults resets all four; Replay intro restarts the reveal. The intro temporarily increases opacity, but a manual edit applies the selected actual opacity immediately. Settings changes, hiding and switching apps do not replay it. Closing controls leaves the overlay running.

Hide/show shortcut: **Ctrl+Option+Command+G** on macOS; **Ctrl+Alt+G** on Windows, if available. Quit from the menu/tray. The overlay passes mouse input through but can visually obscure text. It hides and pauses for other foreground apps or missing/minimized target windows, remaining visible while its own appearance panel is in use. Rendering is capped around 30 fps; OS reduced-motion settings produce a static character.

The animation has no API calls, external assets or local HTTP server. Windows serves bundled files through a WebView2 virtual host and blocks external page requests. WebView2's own runtime servicing is managed separately by Microsoft. The companion does not require macOS Accessibility or Screen Recording permission. Fullscreen, mixed-DPI and physical multi-monitor behavior require further manual verification.

## Uninstall

**macOS:** run `python3 manage.py uninstall` or double-click `卸载.command`. This preserves Codex and the source checkout. To uninstall manually, quit from the sun menu, unload optional startup with `launchctl bootout gui/$(id -u)/local.codex.aura`, and delete:

- `~/Applications/Codex Aura.app` (or the location where you placed it).
- `~/Library/LaunchAgents/local.codex.aura.plist`, if present.
- `~/Library/Application Support/Codex Aura` for preferences and optional diagnostics.

**Windows:** quit from the tray and use Settings → Apps → Installed apps → Codex Aura → Uninstall, or the Start menu uninstaller. The uninstaller removes app files and shortcuts, including its login-startup shortcut, and offers to remove settings/cache. Silent uninstall preserves settings. To remove that data manually after quitting, delete `%LOCALAPPDATA%\Codex Aura`. Do not remove the shared WebView2 Runtime as part of removing this app.

## Development and verification

```sh
# macOS and shared renderer regressions (requires Node.js and Python 3)
./scripts/test.sh
# Cross-platform Windows settings/policy tests (requires .NET SDK 10.0.401)
dotnet run --project windows/CoreTests -c Release
```

On Windows with .NET SDK 10.0.401 and Inno Setup 6 installed:

```powershell
./windows/build.ps1 -Installer
```

This produces a self-contained x64 application and the installer under `windows/installer-output/`. WebView2 SDK 1.0.4258.31 is locked in `packages.lock.json`. CI checks macOS regressions, Windows tests, native rendering against an isolated fixture and installer/uninstaller behavior. It publishes only Windows installer artifacts. Exact versions, results and outstanding manual checks are in [verification](docs/verification.md).

`source/` holds the macOS host; `windows/CodexAura/` holds the Windows host; `web/` is shared. [Specifications](specs/windows-x64.md) describe behavior, and [DESCRIPTION.md](DESCRIPTION.md) contains three-language repository descriptions.

## Assets and license

Original generated character images and derived contour textures are documented in [credits](web/CREDITS.html) and [prompts](web/PROMPTS.txt). No frames, audio or source code from the reference video are included. The character uses 2.5D texture deformation, not a full 3D or Live2D model.

Copyright © 2026 pikad520. Project code, documentation and original assets use the [MIT License](LICENSE). [Chinese](LICENSE.zh-CN.md) and [Japanese](LICENSE.ja.md) are reference translations; English governs. Dependencies retain their own licenses; Windows bundles their notices. Codex Aura is not affiliated with or endorsed by OpenAI.
