#define AppVersion "1.3.0"
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

[Tasks]
Name: "startup"; Description: "Start Codex Aura when I sign in"; Flags: unchecked
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Codex Aura"; Filename: "{app}\CodexAura.exe"
Name: "{group}\Uninstall Codex Aura"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Codex Aura"; Filename: "{app}\CodexAura.exe"; Tasks: desktopicon
Name: "{userstartup}\Codex Aura"; Filename: "{app}\CodexAura.exe"; Tasks: startup

[Run]
Filename: "{app}\CodexAura.exe"; Description: "Launch Codex Aura"; Flags: nowait postinstall skipifsilent

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
  Result := HasWebView2;
  if not Result then begin
    if WizardSilent then
      Log('Microsoft Edge WebView2 Runtime is required. Install it before running setup.')
    else if MsgBox('Microsoft Edge WebView2 Runtime is required. Install it from Microsoft, then run this installer again. Open the download page now?',
      mbInformation, MB_YESNO) = IDYES then
      ShellExec('open', 'https://developer.microsoft.com/microsoft-edge/webview2/', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then begin
    // Preferences and browser cache are separate from the installation and kept by default.
    if not UninstallSilent then
      if MsgBox('Also remove Codex Aura appearance settings and browser cache?', mbConfirmation, MB_YESNO) = IDYES then
        DelTree(ExpandConstant('{localappdata}\Codex Aura'), True, True, True);
  end;
end;
