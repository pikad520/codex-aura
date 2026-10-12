# Codex Aura · 曦光浮层

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md)

为 macOS Codex 桌面应用增添会眨眼、发丝轻摆的动漫浮层，支持鼠标穿透、实时调色与一次性开场动画。

Codex Aura 是独立的非官方伴随应用，不修改 Codex。人物由四张原创纹理通过 Canvas 和 WebGL 在本地实时渲染，无需播放视频、API Key 或网络连接。当前应用菜单和控件为中文，仓库提供中英日三语文档。

## 功能

- 透明浮层覆盖前台 Codex 窗口，鼠标操作穿透到下方窗口。
- 每次启动只播放一次「线稿 → 上色」，之后持续眨眼、摆发；可从菜单手动重播。
- 通过滑块或数字输入实时调整实际不透明度、饱和度、对比度和亮度，自动保存设置。
- 切换到其他应用、没有可见目标窗口或手动隐藏时，隐藏浮层并暂停绘制；操作浮层自己的控制面板时保持显示。
- 渲染上限约 30 帧/秒；开启系统「减少动态效果」后显示静态人物。
- 支持可选的登录自启，以及脚本卸载和手动卸载。

## 环境要求与当前状态

- 构建目标为 macOS 12 及以上，尚未逐一验证所有系统版本。
- 目标应用的 bundle ID 必须为 `com.openai.codex`，不同版本显示的应用名称可能不同。不会自动支持其他标识的应用。
- 构建需要 Xcode Command Line Tools 和 Swift 5.7+ 编译器。`build.sh` 按本机架构构建；现有原生验证在 Apple 芯片 Mac 上完成，Intel 尚未验证。
- Python 3 仅供管理脚本使用，Node.js 仅供 JavaScript 测试使用；运行已构建的应用不需要它们。
- 本地构建使用 ad-hoc 临时签名，尚未经过 Apple 公证。下载的构建可能受到 Gatekeeper 拦截；仓库目前尚未提供正式签名、公证的公开发行版。

## 构建与启动

在项目根目录打开终端：

```sh
# 尚未安装 Apple 开发工具时执行。
xcode-select --install

./build.sh
open 'Codex Aura.app'
```

生成的 `Codex Aura.app` 已加入 Git 忽略规则。无需 npm 安装或本地 HTTP 服务，也可把构建后的应用拖入 Applications 文件夹再打开。

如需安装到 `~/Applications/Codex Aura.app`：

```sh
python3 manage.py install
```

也可以双击 `安装并启动.command`；Finder 启动脚本需要 `/usr/bin/python3`，上述命令则使用 PATH 中的 `python3`。安装不会新增登录自启。通过脚本安装后，如需自启，单独执行：

```sh
python3 manage.py enable-login
```

对应的 Finder 启动脚本为 `开启登录自启.command`。使用脚本更新应用时，会保留已明确开启的自启设置。

## 控制方式

点击菜单栏太阳图标 → **调色控制面板…**。首次启动时面板会自动显示。拖动滑块即可实时预览；也可输入数字，按回车或离开输入框应用。

| 参数 | 默认值 | 范围 |
| --- | --- | --- |
| 实际不透明度 | 20% | 0–100% |
| 饱和度 | 1.30 倍 | 0–2 倍 |
| 对比度 | 1.10 倍 | 0.5–2 倍 |
| 亮度 | 0.70 倍 | 0.2–1.5 倍 |

**恢复默认**回到上述数值；**重播开场**重新播放开场。开场会短暂提高不透明度，手动调整任意外观参数后立即使用所选实际不透明度。调整设置、切换应用不会重播开场，关闭控制面板后浮层继续运行。

通过菜单中的**隐藏浮层 / 显示浮层**切换，也可使用 **Control + Option + Command + G**（快捷键未被占用时）。选择**退出曦光浮层**可退出应用。

## 行为与隐私

动画根据应用是否位于前台播放，不表示模型运行状态或真实加载进度，不读取聊天内容。同一目标应用内的其他页面也可能显示浮层。伴随应用不需要辅助功能或录屏权限。

浮层允许鼠标穿透，但画面仍会在视觉上遮挡文字，可降低不透明度。原生全屏、多显示器实际切换尚未完整验证。人物采用 2.5D 纹理形变，不是完整的 3D 或 Live2D 骨骼模型。

## 卸载

通过脚本安装的版本可执行：

```sh
python3 manage.py uninstall
```

也可双击 `卸载.command`。卸载会停止伴随应用，移除已安装应用、登录自启和设置，保留 Codex 与当前源码目录。

手动卸载步骤：

1. 点击太阳菜单 → **退出曦光浮层**。
2. 如曾开启自启，执行 `launchctl bootout gui/$(id -u)/local.codex.aura`，或在删除下列文件后注销登录。
3. 删除 `~/Library/LaunchAgents/local.codex.aura.plist`（若存在）。
4. 删除 `~/Applications/Codex Aura.app`；如果手动放到了其他位置，也删除那份应用。
5. 删除 `~/Library/Application Support/Codex Aura`，清理设置及可选诊断文件。

## 开发与测试

```sh
./scripts/test.sh
```

该命令构建应用，执行 Swift 外观设置和窗口策略检查、Node 渲染器及一次性开场回归、临时用户目录内的 Python 安装卸载测试，并验证签名。安装器测试不会修改你已安装的应用或自启项。这些检查不能替代各 macOS 版本下的实际窗口交互测试。

| 路径 | 用途 |
| --- | --- |
| `source/` | 原生窗口、菜单、调色面板、设置和 WebKit 桥接 |
| `web/` | Canvas/WebGL 渲染器与原创人物纹理 |
| `build.sh` | 本地应用构建和临时签名 |
| `manage.py`、`*.command` | 安装、可选自启和卸载 |
| `tests/`、`scripts/test.sh` | 自动检查 |
| `specs/repository.md` | 迁移范围及验收条件 |
| [DESCRIPTION.md](DESCRIPTION.md) | 中英日三语项目简介 |

## 素材与许可证

本项目使用新生成的人物图和派生轮廓纹理，不包含参考视频的截图、音频或工程源码。见[素材说明](web/CREDITS.html)和[生成提示词](web/PROMPTS.txt)。

版权所有 © 2026 pikad520。项目代码、文档及随附原创素材以 [MIT 许可证](LICENSE)分发。[中文](LICENSE.zh-CN.md)和[日文](LICENSE.ja.md)版本为参考译本，以英文许可证为准。Codex Aura 与 OpenAI 无隶属或背书关系，产品名称归其各自所有者所有。
