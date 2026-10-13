Codex Aura 1.5.0 — quick help / 使用说明 / 使い方

English
macOS music: choose a folder to autoplay its top-level audio. The transparent right-third
toolbar beneath the character has playlist (5 visible rows), loop/random, previous/play/next and volume;
seek/time sit below. Latin → pinyin → kana → other filename order. Previous uses
play history; random avoids immediate repeats. Protected hair still follows music.
The sun menu hides/shows music controls and disables/enables passive click ripples.
Hiding controls keeps music/hair response; Reduce Motion disables ripples. Toggles apply for this run.
Switching apps keeps audio playing; Quit stops it. No saved folder/position. Windows has no player.
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
Language: Follow system / English / 简体中文 / 日本語. First launch follows the OS
UI language; unsupported languages use English. Changes apply immediately and save.
Restore defaults keeps language and character; language changes do not replay the intro.
Windows Setup also offers three languages; its choice is separate from the app setting.
Select Golden · Waves or Blue · Hime cut. Selection saves; switching does not replay.
Restore defaults keeps your selected character.
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
macOS 音乐：标题栏右侧三分之一的双行透明控件，位于人物下方且无背景。选文件夹自动播放，不含子文件夹；
上排为文件夹、5 行可滚动歌单、循环/随机、上一首、播放暂停、下一首和音量，下排为进度与时间。
文件名按字母、拼音、五十音、其他排序；上一首返回历史，随机不连续重复。发丝保护与平滑连动保留。
太阳菜单可隐藏/显示音频控件、关闭/开启点击波纹，本次运行生效。隐藏控件继续播放和发丝响应；
波纹只读监听，不改变原点击。减少动态效果时波纹关闭。
切换应用继续播放，退出停止；不保存文件夹和进度。Windows 暂未提供播放器。
macOS 只提供源码：安装 Xcode Command Line Tools，执行 ./build.sh，打开生成的
Codex Aura.app。自动使用 ad-hoc 本地临时签名，无需付费开发者账号或 Developer ID。
不分发 Mac ZIP/DMG。已验证 macOS 26.5.1（25F80）、arm64、Swift 6.3.2，目标应用
26.1007.30912（20156），bundle ID com.openai.codex；Intel 未验证。
Windows 只提供 Windows 11 x64 安装器，已包含 .NET 运行时；需要 WebView2 Runtime。
缺少 WebView2 时提示打开微软下载页，安装后重试。安装器尚未正式签名。
真实 Codex.exe 窗口交互尚未验证，构建及自动测试记录见 docs/verification.md。
通过太阳菜单/托盘的调色面板调整四个参数，默认 20%、1.30、1.10、0.70，自动保存。
语言可选“跟随系统 / English / 简体中文 / 日本語”，首次启动默认系统语言，
不支持的语言回退英语。更改立即生效、自动保存；恢复默认保留语言与角色。
Windows 安装器同样提供三语选择，与应用内语言独立。
角色可选“金发 · 大波浪”或“蓝发 · 公主切”，自动保存。切换不重播，恢复默认保留角色。
每次启动只播放一次开场，之后持续眨眼摆发，隐藏时暂停。动画不表示模型进度。
macOS 卸载可执行 python3 manage.py uninstall 或 卸载.command；手动路径见上方。
Windows 从系统“已安装的应用”卸载，可选清理数据。静默卸载保留数据；退出后可手动
删除 %LOCALAPPDATA%\Codex Aura。保留其他应用共享的 WebView2 Runtime。

日本語
macOS 音楽：タイトルバー右側の キャラクターの下の背景なし 2 段ツールバー。フォルダー直下の音声を自動再生します。
5 行のリスト、ループ/ランダム、前/再生/次、音量、下段の位置と時間を操作できます。
ラテン文字、ピンイン、五十音、その他の順。前の曲は履歴を戻り、ランダムは同じ曲を続けません。
髪の保護と滑らかな連動を維持。
太陽メニューで音楽コントロールとクリックの波紋を切り替えます。今回の起動中に適用されます。
非表示でも音楽と髪の反応を維持し、視差効果を減らす設定では波紋を停止。元のクリックは変更しません。切り替え中も再生、終了で停止。パスと位置は保存せず、Windows は未対応です。
macOS はソースのみ提供します。Xcode Command Line Tools を導入し、./build.sh を
実行して生成したアプリを開きます。ローカル ad-hoc 署名のため、有料開発者アカウントや
Developer ID は不要です。Mac ZIP/DMG は提供しません。検証環境は macOS 26.5.1、
arm64、Swift 6.3.2、対象アプリ 26.1007.30912（20156）です。Intel は未検証です。
Windows は Windows 11 x64 インストーラーのみ。.NET ランタイムは同梱しています。
WebView2 Runtime がない場合は Microsoft のダウンロードページを案内します。
インストーラーは未署名で、実際の Codex.exe 操作は未検証です。自動テストの範囲と
結果は docs/verification.md を参照してください。
太陽メニュー／トレイから色調整パネルを開きます。初期値は 20%、1.30、1.10、0.70。
言語は「システムに従う / English / 简体中文 / 日本語」から選択できます。
初回は OS 言語を使用し、未対応言語は英語になります。即時反映・自動保存に対応し、
初期値に戻しても言語は維持されます。Windows インストーラーの言語は独立しています。
金髪ウェーブ／青髪の姫カットを選択できます。切り替えで再生をやり直しません。
初期値に戻してもキャラクターは維持されます。選択は保存され、イントロは起動時に一度再生します。非表示で停止し、モデルの進捗は示しません。
macOS は python3 manage.py uninstall または 卸载.command で削除できます。
Windows は「インストールされているアプリ」から削除し、設定データの削除も選択できます。
サイレント削除ではデータを保持します。終了後、%LOCALAPPDATA%\Codex Aura を
手動削除することもできます。共有の WebView2 Runtime は削除しないでください。

Full documentation / 完整文档 / 詳細:
README.md · README.zh-CN.md · README.ja.md
Copyright (c) 2026 pikad520. MIT License (LICENSE).
LICENSE.zh-CN.md and LICENSE.ja.md are reference translations; English governs.
Dependencies retain their own licenses. Independent, unofficial companion.
