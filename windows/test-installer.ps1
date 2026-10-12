$ErrorActionPreference = 'Stop'
if ($env:CI -ne 'true' -or -not $env:RUNNER_TEMP) { throw 'Run this isolation test only on a disposable CI runner.' }
# CI-only isolation: do not use the user's normal app/settings directories.
$destination = Join-Path $env:RUNNER_TEMP 'CodexAura-install-test'
$setup = Get-ChildItem "$PSScriptRoot/installer-output/*setup.exe" | Select-Object -First 1
$process = Start-Process $setup.FullName -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/DIR=`"$destination`"", '/TASKS=') -PassThru -Wait
if ($process.ExitCode -ne 0) { throw "Installer failed: $($process.ExitCode)" }
foreach ($file in @('CodexAura.exe', 'Web/index.html', 'Web/assets/character.png', 'Docs/LICENSE', 'Docs/ThirdParty/WebView2-LICENSE.txt', 'Docs/ThirdParty/NET-LICENSE.txt', 'unins000.exe')) {
    if (-not (Test-Path (Join-Path $destination $file))) { throw "Missing installed file: $file" }
}
if (Test-Path "$env:APPDATA/Microsoft/Windows/Start Menu/Programs/Startup/Codex Aura.lnk") {
    throw 'Startup must not be enabled by default.'
}
$process = Start-Process (Join-Path $destination 'unins000.exe') -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') -PassThru -Wait
if ($process.ExitCode -ne 0) { throw "Uninstaller failed: $($process.ExitCode)" }
if (Test-Path (Join-Path $destination 'CodexAura.exe')) { throw 'Installed executable was not removed.' }
Write-Output 'PASS: Windows x64 installer, bundled resources, default startup off and uninstall'
