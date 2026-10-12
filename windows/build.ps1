param([switch]$Installer)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    dotnet restore windows/CodexAura/CodexAura.csproj --locked-mode
    if ($LASTEXITCODE -ne 0) { throw 'Dependency restore failed.' }
    dotnet publish windows/CodexAura/CodexAura.csproj -c Release --no-restore -o windows/publish
    if ($LASTEXITCODE -ne 0) { throw 'Windows publish failed.' }
    if ($Installer) {
        $iscc = (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Source
        if (-not $iscc) { $iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe" }
        if (-not (Test-Path $iscc)) { throw 'Install Inno Setup 6, then run this command again.' }
        & $iscc windows/installer.iss
        if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed.' }
        Get-FileHash windows/installer-output/*.exe -Algorithm SHA256 |
            ForEach-Object { "$($_.Hash.ToLower())  $([IO.Path]::GetFileName($_.Path))" } |
            Set-Content windows/installer-output/SHA256SUMS.txt
    }
} finally { Pop-Location }
