# Third-party components / 第三方组件 / サードパーティ

Project-authored code and original character assets use the root MIT license. Dependency licenses are separate.

Windows uses Microsoft.Web.WebView2 SDK 1.0.4258.31 and a self-contained .NET 10 runtime. The installer includes the SDK's LICENSE and NOTICE, the .NET runtime LICENSE and THIRD-PARTY-NOTICES, and the Windows Desktop runtime LICENSE under `Docs/ThirdParty/`. Windows SDK .NET projections (Microsoft.Windows.SDK.NET / WinRT.Runtime) are included for native composition; their SDK terms are linked below. WebView2 Evergreen Runtime is installed separately from Microsoft and is not bundled or uninstalled by Codex Aura. Inno Setup builds the installer under its own license.

中文：项目 MIT 许可证不替代依赖的许可证。Windows 安装器在 `Docs/ThirdParty/` 随附 WebView2 SDK、.NET 与 Windows Desktop 运行时的授权声明。WebView2 Evergreen Runtime 由用户单独从微软安装，不随本应用卸载。

日本語：本プロジェクトの MIT ライセンスは依存コンポーネントのライセンスを置き換えません。Windows は `Docs/ThirdParty/` に WebView2 SDK、.NET と Windows Desktop ランタイムの通知を同梱します。WebView2 Evergreen Runtime は Microsoft から別途インストールし、本アプリと一緒には削除しません。

Sources: [WebView2 SDK package](https://www.nuget.org/packages/Microsoft.Web.WebView2/1.0.4258.31), [.NET](https://github.com/dotnet/runtime), [WPF](https://github.com/dotnet/wpf), [Inno Setup](https://jrsoftware.org/isinfo.php), [Windows SDK terms](https://aka.ms/WinSDKLicenseURL).
