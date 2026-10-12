曦光 · Codex 全窗口动画浮层 v1.2.0

实时调色
菜单栏太阳图标 →「调色控制面板…」。首次升级会自动显示面板，不抢输入焦点。
四个滑块拖动时实时生效；也可点击右侧数字框输入数值，按回车或离开输入框应用。
  实际不透明度：0–100%，每格 1%；20 就是最终 20%，不再有隐藏的增强倍率。
  饱和度：0–2 倍，每格 0.01。
  对比度：0.5–2 倍，每格 0.01。
  亮度：0.2–1.5 倍，每格 0.01。
当前默认值：20%、1.30、1.10、0.70。「恢复默认」回到这组值。
改动立即应用，不重播动画；自动保存，退出再打开仍保留。关闭面板后浮层继续运行。
调整期间浮层保持显示；只有控制面板接收输入，动画浮层仍然鼠标穿透。
原「基础不透明度／浅色背景增强」菜单已合并为直接控制，旧设置会迁移成相同显示效果。

安装与启动
1. 双击「安装并启动.command」。安装到 ~/Applications/Codex Aura.app，无需管理员权限。
2. 回到 Codex（目标 bundle ID 为 com.openai.codex，显示名称因版本而异）。浮层覆盖前台窗口全部区域。
3. 菜单栏太阳图标可隐藏、重播、打开调色面板或退出。
4. Ctrl + Option + Command + G 隐藏/显示（快捷键未被其他程序占用时）。
5. 若要以后登录自动启动，单独双击「开启登录自启.command」。默认不新增自启。

动画行为
每次启动只播放一次「线稿 → 上色」，完成后保持彩色，持续眨眼、摆发。
切换应用、隐藏/显示、调整颜色都不会重播；只有重新启动或「重播开场」才重播。
开场有短暂亮度增强；手动调整任一参数后立即按面板百分比显示。完成开场后始终按所选实际不透明度显示。
鼠标穿透、不抢焦点；其他应用位于前台、关闭/最小化 Codex 或手动隐藏后停止绘制。
最多约 30 帧/秒、1 倍画布分辨率；系统「减少动态效果」开启时显示静态人物。
根据应用前台状态播放，不读取聊天内容、不判断模型任务进度。ChatGPT/Codex 共用应用的其他页面也会显示。
全窗口动画仍有视觉遮挡，可降低实际不透明度。无需 API Key、辅助功能或录屏授权，不发网络请求。

卸载：脚本方式
双击本包「卸载.command」，停止浮层并删除以下三个自有路径，保留 Codex 和本源码包：
  ~/Applications/Codex Aura.app
  ~/Library/LaunchAgents/local.codex.aura.plist
  ~/Library/Application Support/Codex Aura

手动卸载：无需脚本
1. 菜单栏太阳图标 →「退出曦光浮层」。
2. Finder → 前往 → 前往文件夹，输入 ~/Library/LaunchAgents/，将 local.codex.aura.plist 移到废纸篓（没有则跳过）。
3. 前往 ~/Applications/，将 Codex Aura.app 移到废纸篓。
4. 前往 ~/Library/Application Support/，将 Codex Aura 文件夹移到废纸篓（没有则跳过）。
5. 若启用过自启，注销再登录清除本次 launchd 注册，或在终端执行：
   launchctl bootout gui/$(id -u)/local.codex.aura
源码包是备份，不需要时可自行移到废纸篓。

源码
source/main.swift：原生浮层、菜单、窗口跟随、控制桥接。
source/ControlsWindow.swift：四参数原生面板。
source/AppearanceSettings.swift：保存值、范围与旧设置迁移。
web/overlay.js：一次性开场、实时调色、节能调度。
web/character.js、web/assets/：人物纹理、眨眼、发丝形变。
原创素材说明见 web/CREDITS.html、web/PROMPTS.txt。
build.sh 用本机 Xcode/Swift 构建、ad-hoc 签名；按当前机器架构构建，未做 Apple 公证。
manage.py 与 .command：安装、自启和卸载。无需 npm、第三方运行库或 HTTP 服务器。

验证与范围
自动检查涵盖旧设置迁移、参数范围、保存读取、四参数实时桥接、不重播开场、暂停恢复、减少动态效果和安装卸载。
原生窗口跟随、纹理渲染已在本机检查。原生全屏、多显示器实际切换仍未代操作验证；Codex 自身 UI 不在自动化允许范围内。

仓库文档与许可证
English: README.md
简体中文: README.zh-CN.md
日本語: README.ja.md
Copyright (c) 2026 pikad520. MIT License，见同目录 LICENSE。
LICENSE.zh-CN.md 与 LICENSE.ja.md 为参考译本，以英文 LICENSE 为准。
当前应用界面为中文；Codex Aura 是独立非官方伴随应用。
