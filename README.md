# Codex Aura

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md)

An animated anime overlay for Codex on macOS, with blinking eyes, flowing hair, click-through interaction, live appearance controls, and a one-time intro.

Codex Aura is an independent, unofficial companion app. It does not modify Codex. The character is rendered locally from four original textures using Canvas and WebGL; no video playback, API key, or network connection is required. The current application menus and controls are in Chinese; this repository provides documentation in three languages.

## Features

- Covers the foreground Codex window with a transparent, mouse-pass-through overlay.
- Plays the line-art-to-color introduction once per launch, then continues blinking and hair movement. Replay is available from the menu.
- Adjusts actual opacity, saturation, contrast and brightness live, with sliders or numeric input. Settings are saved automatically.
- Hides and pauses when another app is foreground, no target window is visible, or the overlay is manually hidden. It remains visible while its own controls are in use.
- Limits rendering to approximately 30 fps and displays a static character when macOS Reduce Motion is enabled.
- Provides optional login startup and both scripted and manual removal.

## Requirements and current status

- macOS 12 or later is the build deployment target; not every supported OS version has been tested.
- The target application's bundle identifier must be `com.openai.codex`. Its displayed app name may differ between versions. Other app identifiers are not supported automatically.
- Build with Xcode Command Line Tools and a Swift 5.7+ compiler. `build.sh` builds for the current machine's architecture. The existing native verification was on Apple silicon; Intel has not been verified.
- Python 3 is needed only for the management scripts; Node.js is needed only for JavaScript tests. Neither is required to run the built app.
- Local builds use ad-hoc signing and are not Apple-notarized. A downloaded build may be blocked by Gatekeeper. This repository does not yet provide a signed, notarized public release.

## Build and run

In a terminal at the project root:

```sh
# Install Apple's developer tools if needed.
xcode-select --install

./build.sh
open 'Codex Aura.app'
```

The generated `Codex Aura.app` is ignored by Git. No npm install or local HTTP server is needed. You can also drag the built app to your Applications folder and open it there.

For installation to `~/Applications/Codex Aura.app`, use:

```sh
python3 manage.py install
```

Or double-click `安装并启动.command`; the Finder launcher expects Python at `/usr/bin/python3`. The CLI above uses the `python3` on your PATH. Installation does not newly enable login startup. To opt in after script installation:

```sh
python3 manage.py enable-login
```

The corresponding Finder launcher is `开启登录自启.command`. An existing startup opt-in is preserved during script-based updates.

## Controls

Open the sun icon in the menu bar, then choose **调色控制面板…** (appearance controls). The panel appears automatically on first launch. Drag a slider or enter a number and press Return or leave the field to apply it.

| Setting | Default | Range |
| --- | --- | --- |
| Actual opacity | 20% | 0–100% |
| Saturation | 1.30× | 0–2× |
| Contrast | 1.10× | 0.5–2× |
| Brightness | 0.70× | 0.2–1.5× |

**恢复默认** restores these defaults; **重播开场** replays the intro. The intro temporarily increases opacity; a manual appearance edit immediately applies the selected actual opacity. Changing settings or switching apps does not restart the intro. Closing the controls leaves the overlay running.

Use **隐藏浮层 / 显示浮层** to hide or show it, or **Control + Option + Command + G** if the shortcut is available. **退出曦光浮层** quits the app.

## Behavior and privacy

The animation follows application foreground state, not model activity or actual loading progress. It does not read chat content. Other pages within the same target app can also show the overlay. No Accessibility or Screen Recording permission is required by the companion.

The overlay passes mouse input through, but can visually cover text; adjust opacity to suit your workspace. Native fullscreen and physical multi-monitor transitions have not been fully verified. The character uses 2.5D texture deformation, not a fully rigged 3D or Live2D model.

## Uninstall

For script-based installation:

```sh
python3 manage.py uninstall
```

Or double-click `卸载.command`. This stops the companion and removes its installed app, login agent and settings, while preserving Codex and this source checkout.

To remove it manually:

1. Choose **退出曦光浮层** from the sun menu.
2. If login startup was enabled, run `launchctl bootout gui/$(id -u)/local.codex.aura`, or log out after removing the files below.
3. Delete `~/Library/LaunchAgents/local.codex.aura.plist` if present.
4. Delete `~/Applications/Codex Aura.app`. If you placed it elsewhere manually, remove that copy as well.
5. Delete `~/Library/Application Support/Codex Aura` to remove settings and optional diagnostics.

## Development and tests

```sh
./scripts/test.sh
```

This builds the app, runs Swift appearance and window-policy checks, Node renderer and intro regressions, Python installation/removal tests in a temporary home, and signature verification. The installer tests do not modify your installed copy or login startup. These checks do not replace testing actual window interaction on each macOS version.

| Path | Purpose |
| --- | --- |
| `source/` | Native window, menu, appearance panel, settings and WebKit bridge |
| `web/` | Canvas/WebGL renderer and original character textures |
| `build.sh` | Local app build and ad-hoc signing |
| `manage.py`, `*.command` | Install, opt-in login startup and uninstall |
| `tests/`, `scripts/test.sh` | Automated checks |
| `specs/repository.md` | Migration scope and acceptance criteria |
| [DESCRIPTION.md](DESCRIPTION.md) | Short descriptions in three languages |

## Assets and license

The project uses newly generated character images and derived contour textures, not frames, audio or source code from the reference video. See [asset credits](web/CREDITS.html) and [generation prompts](web/PROMPTS.txt).

Copyright © 2026 pikad520. Project code, documentation and bundled original assets are distributed under the [MIT License](LICENSE). [Chinese](LICENSE.zh-CN.md) and [Japanese](LICENSE.ja.md) translations are provided for reference; the English license governs. Codex Aura is not affiliated with or endorsed by OpenAI. Product names belong to their respective owners.
