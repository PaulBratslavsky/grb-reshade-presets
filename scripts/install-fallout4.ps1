<#
.SYNOPSIS
    Fallout 4 installer. Auto-detects the game, then delegates the shader/preset
    deployment to install-anygame.ps1.

.DESCRIPTION
    - Locates the Fallout 4 install (or use -GamePath).
    - Delegates to install-anygame.ps1 to download shaders + deploy presets/LUTs.

    ReShade for Fallout 4:
      * Install the ReShade runtime (https://reshade.me) for Fallout4.exe using the
        DirectX 10/11/12 option (Fallout 4 is DirectX 11).
      * Fallout 4 is single-player with NO anti-cheat, so ReShade is completely safe here.
      * If you also use ENB, note ReShade and ENB can be layered but may need d3d11.dll vs
        dxgi.dll ordering care; a ReShade-only setup is simplest.

.PARAMETER GamePath
    Fallout 4 folder (containing Fallout4.exe). Auto-detected if omitted.

.PARAMETER DefaultPreset
    Preset file to set as the active preset (e.g. Cinematic_BladeRunner.ini).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\install-fallout4.ps1
#>
[CmdletBinding()]
param(
    [string]$GamePath,
    [string]$DefaultPreset
)

$ErrorActionPreference = 'Stop'
$exeName = 'Fallout4.exe'

function Find-GamePath {
    $names = @('Fallout 4','Fallout4')
    $roots = @(
        "C:\Program Files (x86)\Steam\steamapps\common",
        "D:\Steam\steamapps\common",
        "E:\Steam\steamapps\common",
        "C:\Program Files (x86)\GOG Galaxy\Games",
        "C:\Program Files\Epic Games",
        "C:\Program Files (x86)\Bethesda.net Launcher\games"
    )
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
    throw "Could not locate Fallout 4. Re-run with -GamePath 'C:\path\to\Fallout 4'."
}

Write-Host "=== Fallout 4 ===" -ForegroundColor Cyan
Write-Host "REMINDER: install ReShade for $exeName using DirectX 10/11/12 (Fallout 4 is DX11)." -ForegroundColor Yellow
Write-Host "Single-player, no anti-cheat - ReShade is safe here." -ForegroundColor Green
Write-Host ""

$p = @{ GamePath = $GamePath }
if ($DefaultPreset) { $p.DefaultPreset = $DefaultPreset }
& (Join-Path $PSScriptRoot 'install-anygame.ps1') @p
