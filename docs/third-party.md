# Third-party components / 第三方组件 / サードパーティ

Project-authored code and original character assets use the root MIT license. Dependency licenses are separate.

Windows uses Microsoft.Web.WebView2 SDK 1.0.4258.31 and a self-contained .NET 10 runtime. The installer includes the SDK's LICENSE and NOTICE, the .NET runtime LICENSE and THIRD-PARTY-NOTICES, and the Windows Desktop runtime LICENSE under `Docs/ThirdParty/`. Windows SDK .NET projections (Microsoft.Windows.SDK.NET / WinRT.Runtime) are included for native composition; their SDK terms are linked below. WebView2 Evergreen Runtime is installed separately from Microsoft and is not bundled or uninstalled by Codex Aura. Inno Setup builds the installer under its own license.

中文：项目 MIT 许可证不替代依赖的许可证。Windows 安装器在 `Docs/ThirdParty/` 随附 WebView2 SDK、.NET 与 Windows Desktop 运行时的授权声明。WebView2 Evergreen Runtime 由用户单独从微软安装，不随本应用卸载。

日本語：本プロジェクトの MIT ライセンスは依存コンポーネントのライセンスを置き換えません。Windows は `Docs/ThirdParty/` に WebView2 SDK、.NET と Windows Desktop ランタイムの通知を同梱します。WebView2 Evergreen Runtime は Microsoft から別途インストールし、本アプリと一緒には削除しません。

Sources: [WebView2 SDK package](https://www.nuget.org/packages/Microsoft.Web.WebView2/1.0.4258.31), [.NET](https://github.com/dotnet/runtime), [WPF](https://github.com/dotnet/wpf), [Inno Setup](https://jrsoftware.org/isinfo.php), [Windows SDK terms](https://aka.ms/WinSDKLicenseURL).

The installer uses unmodified official Chinese (Simplified) and Japanese wizard messages from [jrsoftware/issrc at fc31efcf82e2042bf8417708ddc970f8d83a5ba9](https://github.com/jrsoftware/issrc/tree/fc31efcf82e2042bf8417708ddc970f8d83a5ba9/Files/Languages). They are pinned in `windows/installer-languages/` with their original maintainer notices and the upstream [Inno Setup license](../windows/installer-languages/LICENSE.txt); they are not covered by this project's MIT license. This avoids depending on optional language files in the compiler installation. Project-specific prompts come from `web/locales.json`. See [Inno Setup translations](https://jrsoftware.org/files/istrans/) and [UI-language detection](https://jrsoftware.org/ishelp/topic_setup_languagedetectionmethod.htm).

中文：安装器使用的官方中日文资源以未修改形式保存在 `windows/installer-languages/`，固定来源版本见上方链接，保留原作者声明并随附 Inno Setup 许可证，不适用本项目 MIT 许可证。

日本語：インストーラー用の公式中国語・日本語リソースは、上記の固定バージョンから変更せず `windows/installer-languages/` に収録しています。原著作者の通知と Inno Setup ライセンスを保持しており、本プロジェクトの MIT ライセンスの対象外です。
