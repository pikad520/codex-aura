#define AppVersion "1.5.0"
[Setup]
AppId={{C148D59F-0C96-47F4-8DB5-D67401ED316A}
AppName=Codex Aura
AppVersion={#AppVersion}
AppPublisher=pikad520
AppPublisherURL=https://github.com/pikad520/codex-aura
DefaultDirName={localappdata}\Programs\Codex Aura
DefaultGroupName=Codex Aura
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64os
ArchitecturesInstallIn64BitMode=x64os
MinVersion=10.0.22000
OutputDir=installer-output
OutputBaseFilename=CodexAura-{#AppVersion}-windows-x64-setup
SetupIconFile=CodexAura\aura.ico
UninstallDisplayIcon={app}\CodexAura.exe
LicenseFile=..\LICENSE
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
Uninstallable=yes
LanguageDetectionMethod=uilanguage
ShowLanguageDialog=yes
UsePreviousLanguage=yes

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "zh"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "ja"; MessagesFile: "compiler:Languages\Japanese.isl"

#include "obj\LocalizedMessages.iss"

[Tasks]
Name: "startup"; Description: "{cm:installStartup}"; Flags: unchecked
Name: "desktopicon"; Description: "{cm:installDesktop}"; Flags: unchecked

[Files]
Source: "publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Codex Aura"; Filename: "{app}\CodexAura.exe"
Name: "{group}\{cm:installUninstall}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Codex Aura"; Filename: "{app}\CodexAura.exe"; Tasks: desktopicon
Name: "{userstartup}\Codex Aura"; Filename: "{app}\CodexAura.exe"; Tasks: startup

[Run]
Filename: "{app}\CodexAura.exe"; Description: "{cm:installLaunch}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{app}\CodexAura.exe"; Parameters: "--quit"; Flags: runhidden waituntilterminated; RunOnceId: "StopCodexAura"

[Code]
function HasWebView2: Boolean;
var
  Version: String;
  Key: String;
begin
  Key := 'Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}';
  Result := RegQueryStringValue(HKLM32, Key, 'pv', Version) and
            (Version <> '') and (Version <> '0.0.0.0');
  if not Result then
    Result := RegQueryStringValue(HKCU, Key, 'pv', Version) and
              (Version <> '') and (Version <> '0.0.0.0');
end;

function InitializeSetup: Boolean;
var
  ErrorCode: Integer;
begin
  Log('Codex Aura setup language: ' + ActiveLanguage);
  Result := HasWebView2;
  if not Result then begin
    if WizardSilent then
      Log(CustomMessage('installWebView'))
    else if MsgBox(CustomMessage('installWebView'),
      mbInformation, MB_YESNO) = IDYES then
      ShellExec('open', 'https://developer.microsoft.com/microsoft-edge/webview2/', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then begin
    // Preferences and browser cache are separate from the installation and kept by default.
    if not UninstallSilent then
      if MsgBox(CustomMessage('installRemoveData'), mbConfirmation, MB_YESNO) = IDYES then
        DelTree(ExpandConstant('{localappdata}\Codex Aura'), True, True, True);
  end;
end;
