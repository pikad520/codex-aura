Codex Aura 1.3.0 — quick help / 使用说明 / 使い方

English
macOS: source-only. Install Xcode Command Line Tools, run ./build.sh, then
open 'Codex Aura.app'. The build uses a local ad-hoc signature; no Developer ID
or paid Apple developer account is needed. No Mac ZIP/DMG is distributed.
Verified locally: macOS 26.5.1 (25F80), arm64, Swift 6.3.2; target desktop app
26.1007.30912 (20156), bundle ID com.openai.codex. Intel is unverified.
Windows: Windows 11 x64 installer only. Requires WebView2 Runtime; .NET runtime
is bundled. Setup prompts for the Microsoft download page if WebView2 is missing.
The current installer is unsigned. Real Codex.exe interaction remains unverified;
see docs/verification.md for build, automated native and installer test results.

Open the sun menu/tray icon → 调色控制面板… / Appearance… to adjust appearance.
Defaults: actual opacity 20%, saturation 1.30, contrast 1.10, brightness 0.70.
Changes save automatically. Intro runs once; Replay restarts it. Blink/hair motion
continues, pauses when hidden, and respects the OS reduced-motion setting.
Toggle: macOS Ctrl+Option+Command+G; Windows Ctrl+Alt+G (if available).
Quit from the menu/tray. Animation follows foreground state, not model progress.

macOS uninstall: python3 manage.py uninstall, or 卸载.command.
Manual: quit, unload optional startup with:
  launchctl bootout gui/$(id -u)/local.codex.aura
Then remove the app (normally ~/Applications/Codex Aura.app),
~/Library/LaunchAgents/local.codex.aura.plist, and
~/Library/Application Support/Codex Aura.
Windows uninstall: Settings → Apps → Installed apps → Codex Aura → Uninstall.
The uninstaller removes the app and shortcuts and offers to delete data.
Silent uninstall preserves data. After quitting, data can be removed manually at
%LOCALAPPDATA%\Codex Aura. Do not remove shared WebView2 Runtime.

简体中文
macOS 只提供源码：安装 Xcode Command Line Tools，执行 ./build.sh，打开生成的
Codex Aura.app。自动使用 ad-hoc 本地临时签名，无需付费开发者账号或 Developer ID。
不分发 Mac ZIP/DMG。已验证 macOS 26.5.1（25F80）、arm64、Swift 6.3.2，目标应用
26.1007.30912（20156），bundle ID com.openai.codex；Intel 未验证。
Windows 只提供 Windows 11 x64 安装器，已包含 .NET 运行时；需要 WebView2 Runtime。
缺少 WebView2 时提示打开微软下载页，安装后重试。安装器尚未正式签名。
真实 Codex.exe 窗口交互尚未验证，构建及自动测试记录见 docs/verification.md。
通过太阳菜单/托盘的调色面板调整四个参数，默认 20%、1.30、1.10、0.70，自动保存。
每次启动只播放一次开场，之后持续眨眼摆发，隐藏时暂停。动画不表示模型进度。
macOS 卸载可执行 python3 manage.py uninstall 或 卸载.command；手动路径见上方。
Windows 从系统“已安装的应用”卸载，可选清理数据。静默卸载保留数据；退出后可手动
删除 %LOCALAPPDATA%\Codex Aura。保留其他应用共享的 WebView2 Runtime。

日本語
macOS はソースのみ提供します。Xcode Command Line Tools を導入し、./build.sh を
実行して生成したアプリを開きます。ローカル ad-hoc 署名のため、有料開発者アカウントや
Developer ID は不要です。Mac ZIP/DMG は提供しません。検証環境は macOS 26.5.1、
arm64、Swift 6.3.2、対象アプリ 26.1007.30912（20156）です。Intel は未検証です。
Windows は Windows 11 x64 インストーラーのみ。.NET ランタイムは同梱しています。
WebView2 Runtime がない場合は Microsoft のダウンロードページを案内します。
インストーラーは未署名で、実際の Codex.exe 操作は未検証です。自動テストの範囲と
結果は docs/verification.md を参照してください。
太陽メニュー／トレイから色調整パネルを開きます。初期値は 20%、1.30、1.10、0.70。
自動保存され、イントロは起動時に一度再生します。非表示で停止し、モデルの進捗は示しません。
macOS は python3 manage.py uninstall または 卸载.command で削除できます。
Windows は「インストールされているアプリ」から削除し、設定データの削除も選択できます。
サイレント削除ではデータを保持します。終了後、%LOCALAPPDATA%\Codex Aura を
手動削除することもできます。共有の WebView2 Runtime は削除しないでください。

Full documentation / 完整文档 / 詳細:
README.md · README.zh-CN.md · README.ja.md
Copyright (c) 2026 pikad520. MIT License (LICENSE).
LICENSE.zh-CN.md and LICENSE.ja.md are reference translations; English governs.
Dependencies retain their own licenses. Independent, unofficial companion.
