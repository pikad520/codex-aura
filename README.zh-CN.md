# Codex Aura · 曦光浮层

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md)

为 Codex 增添会眨眼、发丝轻摆的动漫浮层，支持鼠标穿透与实时调色。macOS 从源码自行构建，Windows 提供 x64 安装器。

这是独立的非官方伴随应用，不修改 Codex，也不读取聊天内容。四张原创纹理驱动共享的 Canvas/WebGL 动画：每次启动仅播放一次「线稿 → 上色」，之后持续眨眼、摆发。动画根据应用是否位于前台播放，不代表模型运行状态或真实加载进度。

## 平台与分发方式

| 平台 | 分发方式 | 状态 |
| --- | --- | --- |
| macOS | 源码，本地编译与签名 | Apple Silicon 已验证，Intel 未验证 |
| Windows 11 x64 | `CodexAura-1.3.0-windows-x64-setup.exe` | 预览版，见[验证记录](docs/verification.md) |

不提供 macOS ZIP/DMG、Windows 便携 ZIP、x86 或 ARM64 安装器。macOS 界面为中文，Windows 控件为英文；文档提供中英日三语版本。

## macOS 本地编译与签名

安装包含 Swift 5.7 或更新编译器的 Xcode Command Line Tools，在自己的 Mac 上构建：

```sh
xcode-select --install  # 仅在尚未安装开发工具时执行。
git clone https://github.com/pikad520/codex-aura.git
cd codex-aura
./build.sh
codesign --verify --deep --strict 'Codex Aura.app'
open 'Codex Aura.app'
```

默认构建**无需付费 Apple 开发者账号、Developer ID 证书、签名环境变量或 API Key**。`build.sh` 使用 `codesign --force --sign -` 进行 **ad-hoc 本地临时签名**，用于检查完整性，不代表可信发行者身份，也不执行 Apple 公证。这是本机构建流程，转发生成的应用仍可能触发 Gatekeeper。修改随附资源后请重新构建。正式分发签名可参考 [Apple 文档](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/)。

脚本按当前 Mac 架构生成应用，最低部署目标为 macOS 12.0。实际本地验证环境为 **macOS 26.5.1（25F80）、arm64、Swift 6.3.2**；目标应用版本 **26.1007.30912（20156）**，bundle ID 为 `com.openai.codex`。其他应用标识不会自动匹配；最低部署目标不等于所有系统版本均已测试。

可将生成的应用拖入 Applications。也可使用 Python 3 安装到 `~/Applications/Codex Aura.app`：

```sh
python3 manage.py install
# 通过脚本安装后，可选开启登录自启：
python3 manage.py enable-login
```

Finder 脚本 `安装并启动.command`、`开启登录自启.command` 使用 `/usr/bin/python3`；上述命令使用 PATH 中的 `python3`。运行应用本身不需要 Python。安装不会新增自启，更新时保留此前明确开启的自启设置。

## Windows x64 安装器

从 [Releases](https://github.com/pikad520/codex-aura/releases) 下载 x64 Setup。开发构建也可在 [GitHub Actions](https://github.com/pikad520/codex-aura/actions/workflows/verify.yml) 的安装器产物中取得（可能需要登录）。Actions 下载容器中包含安装器与 SHA-256 校验文件，不是便携版。

要求 **Windows 11 x64**（build 22000 或更新）以及 [Microsoft Edge WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/)。如果缺少 Runtime，安装器会询问是否打开微软下载页；安装 Runtime 后重新运行 Setup，不会静默下载。应用已包含 .NET 运行时，使用者不需要 .NET SDK、Python 或 Node.js。

安装器默认安装到 `%LOCALAPPDATA%\Programs\Codex Aura`，无需管理员权限。登录自启和桌面快捷方式均可选，默认关闭。从开始菜单启动后打开 Codex。窗口层当前按前台进程名 **`Codex.exe`** 匹配，不区分大小写，不依赖窗口标题；其他可执行文件名不会自动匹配。

当前安装器**未进行发行者签名**，Windows 可能显示未知发布者、SmartScreen 提示，或按系统策略阻止运行。使用前核对来源和校验值。Windows 真实 Codex 的端到端验证尚未完成，验证记录区分专用测试窗口和实际应用兼容性。

## 操作与行为

使用 macOS 菜单栏或 Windows 通知区域的太阳图标，选择 **调色控制面板… / Appearance…**。滑块和数值输入实时生效并自动保存。macOS 首次启动自动显示面板；Windows 从托盘菜单或双击托盘图标打开。

| 参数 | 默认值 | 范围 |
| --- | --- | --- |
| 实际不透明度 | 20% | 0–100% |
| 饱和度 | 1.30 倍 | 0–2 倍 |
| 对比度 | 1.10 倍 | 0.5–2 倍 |
| 亮度 | 0.70 倍 | 0.2–1.5 倍 |

恢复默认重置四个参数，重播开场重新播放显影。开场会短暂提高不透明度，手动调整后立即使用所选实际值。调整设置、隐藏和切换应用不会重播，关闭控制面板后浮层继续运行。

隐藏/显示快捷键：macOS 为 **Ctrl+Option+Command+G**，Windows 为 **Ctrl+Alt+G**，均需快捷键可用。通过菜单或托盘退出。浮层鼠标穿透，但画面可能遮挡文字；其他应用在前台、目标关闭或最小化时隐藏并暂停，操作自己的调色面板时保持显示。绘制上限约 30 fps，系统减少动态效果设置会使人物静止。

动画不调用外部 API，不加载外部素材，不启动 HTTP 服务。Windows 通过 WebView2 虚拟主机读取随附资源，并阻止页面外部请求；WebView2 自身运行时更新由微软独立管理。伴随应用不需要 macOS 辅助功能或录屏权限。全屏、混合 DPI 和物理多显示器行为仍需更多实机验证。

## 卸载

**macOS：**运行 `python3 manage.py uninstall` 或双击 `卸载.command`，保留 Codex 和源码目录。手动卸载时，从太阳菜单退出；如曾开启自启，执行 `launchctl bootout gui/$(id -u)/local.codex.aura`，再删除：

- `~/Applications/Codex Aura.app`（或手动放置的位置）。
- `~/Library/LaunchAgents/local.codex.aura.plist`（若存在）。
- `~/Library/Application Support/Codex Aura`，清理设置及可选诊断文件。

**Windows：**从托盘退出，前往「设置 → 应用 → 已安装的应用 → Codex Aura → 卸载」，或使用开始菜单中的卸载入口。卸载器移除应用和快捷方式，包括其登录自启快捷方式，并询问是否清理设置/缓存。静默卸载保留设置；退出应用后可手动删除 `%LOCALAPPDATA%\Codex Aura` 清理数据。无需卸载供其他应用共享的 WebView2 Runtime。

## 开发与验证

```sh
# macOS 与共享动画回归测试，需要 Node.js 和 Python 3
./scripts/test.sh
# Windows 设置/策略测试，可跨平台运行，需要 .NET SDK 10.0.401
dotnet run --project windows/CoreTests -c Release
```

Windows 开发环境安装 .NET SDK 10.0.401 和 Inno Setup 6 后执行：

```powershell
./windows/build.ps1 -Installer
```

生成包含 .NET 运行时的 x64 应用，安装器位于 `windows/installer-output/`。WebView2 SDK 1.0.4258.31 由 `packages.lock.json` 锁定。CI 检查 macOS 回归、Windows 测试、独立测试窗口的原生渲染及安装卸载，仅上传 Windows 安装器产物。具体版本、结果和未完成的手动检查见[验证记录](docs/verification.md)。

`source/` 为 macOS 窗口层，`windows/CodexAura/` 为 Windows 窗口层，`web/` 为共享动画。[规格](specs/windows-x64.md)描述行为，[DESCRIPTION.md](DESCRIPTION.md)保存三语项目简介。

## 素材与许可证

原创生成的人物图及派生轮廓纹理见[素材说明](web/CREDITS.html)和[提示词](web/PROMPTS.txt)。不包含参考视频的截图、音频或源码；人物采用 2.5D 纹理形变，不是完整的 3D 或 Live2D 模型。

版权所有 © 2026 pikad520。项目代码、文档及原创素材使用 [MIT 许可证](LICENSE)；[中文](LICENSE.zh-CN.md)和[日文](LICENSE.ja.md)为参考译本，以英文为准。依赖使用各自许可证，Windows 包含其声明。Codex Aura 与 OpenAI 无隶属或背书关系。
