<#
.SYNOPSIS
    Copies the custom presets from this repo into the Breakpoint game folder.
    Use this after editing a preset in the repo, or to pull new presets in.

.PARAMETER GamePath
    Breakpoint folder (containing GRB.exe). Auto-detected if omitted.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\deploy-presets.ps1
#>
[CmdletBinding()]
param([string]$GamePath)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not $GamePath) {
    $try = "C:\Program Files (x86)\Steam\steamapps\common\Ghost Recon Breakpoint"
    if (Test-Path (Join-Path $try "GRB.exe")) { $GamePath = $try }
}
if (-not $GamePath -or -not (Test-Path (Join-Path $GamePath "GRB.exe"))) {
    throw "Set -GamePath 'C:\path\to\Ghost Recon Breakpoint'."
}

$presets = Get-ChildItem (Join-Path $repoRoot "presets") -Filter *.ini
Copy-Item $presets.FullName -Destination $GamePath -Force
Write-Host "Deployed $($presets.Count) preset(s) to $GamePath :" -ForegroundColor Green
$presets | ForEach-Object { Write-Host "  - $($_.Name)" }
Write-Host "In-game: press Home, then reload / pick the preset from the dropdown." -ForegroundColor Cyan
