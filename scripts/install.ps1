<#
.SYNOPSIS
    Ghost Recon Breakpoint installer. Auto-detects the game, then delegates the actual
    shader/preset deployment to install-anygame.ps1.

.DESCRIPTION
    - Locates the Breakpoint install (or use -GamePath).
    - Warns about Breakpoint's Vulkan-crash gotcha.
    - Calls install-anygame.ps1 to download shaders + deploy presets/LUTs.

    NOTE: Install the ReShade runtime first (https://reshade.me) for GRB.exe using the
    *DirectX 10/11/12* option. Do NOT use Vulkan — it crashes Breakpoint's renderer.

.PARAMETER GamePath
    Breakpoint folder (containing GRB.exe). Auto-detected from common locations if omitted.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
#>
[CmdletBinding()]
param([string]$GamePath)

$ErrorActionPreference = 'Stop'

function Find-GamePath {
    $candidates = @(
        "C:\Program Files (x86)\Steam\steamapps\common\Ghost Recon Breakpoint",
        "D:\Steam\steamapps\common\Ghost Recon Breakpoint",
        "E:\Steam\steamapps\common\Ghost Recon Breakpoint",
        "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games\Tom Clancy's Ghost Recon Breakpoint",
        "C:\Program Files\Epic Games\Ghost Recon Breakpoint"
    )
    $vdf = "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        Select-String -Path $vdf -Pattern '"path"\s+"([^"]+)"' | ForEach-Object {
            $p = ($_.Matches[0].Groups[1].Value -replace '\\\\','\')
            $candidates += (Join-Path $p "steamapps\common\Ghost Recon Breakpoint")
        }
    }
    foreach ($c in $candidates) { if (Test-Path (Join-Path $c "GRB.exe")) { return $c } }
    return $null
}

if (-not $GamePath) { $GamePath = Find-GamePath }
if (-not $GamePath -or -not (Test-Path (Join-Path $GamePath "GRB.exe"))) {
    throw "Could not locate Ghost Recon Breakpoint. Re-run with -GamePath 'C:\path\to\Ghost Recon Breakpoint'."
}

Write-Host "=== Ghost Recon Breakpoint ===" -ForegroundColor Cyan
Write-Host "REMINDER: ReShade must be installed for GRB.exe using DirectX 10/11/12 (NOT Vulkan)." -ForegroundColor Yellow
Write-Host ""

# Delegate to the portable installer.
& (Join-Path $PSScriptRoot "install-anygame.ps1") -GamePath $GamePath
