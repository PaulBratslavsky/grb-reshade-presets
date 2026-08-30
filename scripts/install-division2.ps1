<#
.SYNOPSIS
    The Division 2 installer. Auto-detects the game, then delegates the shader/preset
    deployment to install-anygame.ps1.

.DESCRIPTION
    - Locates the Tom Clancy's The Division 2 install (or use -GamePath).
    - Delegates to install-anygame.ps1 to download shaders + deploy presets/LUTs.

    ReShade for The Division 2:
      * Install the ReShade runtime (https://reshade.me) for TheDivision2.exe using the
        DirectX 10/11/12 option (the game runs DX11 or DX12 - no Vulkan).
      * The Division 2 is always-online. Visual ReShade is widely used for photo mode and
        is generally accepted, but use it at your own discretion - avoid presets that give
        a gameplay advantage (e.g. cutting fog/darkness for visibility) especially in the
        Dark Zone / PvP.

.PARAMETER GamePath
    The Division 2 folder (containing TheDivision2.exe). Auto-detected if omitted.

.PARAMETER DefaultPreset
    Preset file to set as the active preset (e.g. Cinematic_BladeRunner.ini).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\install-division2.ps1
#>
[CmdletBinding()]
param(
    [string]$GamePath,
    [string]$DefaultPreset
)

$ErrorActionPreference = 'Stop'
$exeName = 'TheDivision2.exe'

function Find-GamePath {
    $names = @(
        "Tom Clancy's The Division 2",
        "The Division 2"
    )
    $roots = @(
        "C:\Program Files (x86)\Steam\steamapps\common",
        "D:\Steam\steamapps\common",
        "E:\Steam\steamapps\common",
        "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games",
        "C:\Program Files\Epic Games"
    )
    # Extra Steam libraries from libraryfolders.vdf
    $vdf = "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        Select-String -Path $vdf -Pattern '"path"\s+"([^"]+)"' | ForEach-Object {
            $p = ($_.Matches[0].Groups[1].Value -replace '\\\\','\')
            $roots += (Join-Path $p 'steamapps\common')
        }
    }
    foreach ($r in $roots) {
        foreach ($n in $names) {
            $candidate = Join-Path $r $n
            if (Test-Path (Join-Path $candidate $exeName)) { return $candidate }
        }
    }
    return $null
}

if (-not $GamePath) { $GamePath = Find-GamePath }
if (-not $GamePath -or -not (Test-Path (Join-Path $GamePath $exeName))) {
    throw "Could not locate The Division 2. Re-run with -GamePath 'C:\path\to\Tom Clancy''s The Division 2'."
}

Write-Host "=== Tom Clancy's The Division 2 ===" -ForegroundColor Cyan
Write-Host "REMINDER: install ReShade for $exeName using DirectX 10/11/12 (DX11/DX12; no Vulkan)." -ForegroundColor Yellow
Write-Host "The Division 2 is always-online - keep ReShade purely visual; avoid PvP-advantage tweaks." -ForegroundColor Yellow
Write-Host ""

$p = @{ GamePath = $GamePath }
if ($DefaultPreset) { $p.DefaultPreset = $DefaultPreset }
& (Join-Path $PSScriptRoot 'install-anygame.ps1') @p
