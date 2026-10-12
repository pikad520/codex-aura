# Verification / 验证记录 / 検証記録

Recorded: 2026-10-12. Application version: 1.3.0.

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
