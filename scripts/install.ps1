<#
.SYNOPSIS
    Installs the shader libraries + custom presets for Ghost Recon Breakpoint ReShade.

.DESCRIPTION
    - Locates the Breakpoint install (or use -GamePath).
    - Downloads the required shader libraries (SweetFX + luluco FXShaders).
    - Deploys them into <game>\reshade-shaders\ (keeping include folders intact).
    - Copies the custom presets from this repo into the game folder.
    - Ensures ReShade.ini has the correct search paths + default preset.

    NOTE: This does NOT install ReShade itself. Install the ReShade runtime first
    (https://reshade.me) for GRB.exe using the *DirectX 10/11/12* option. Do NOT use
    the Vulkan option — it crashes Breakpoint's renderer (see README).

.PARAMETER GamePath
    Full path to the Ghost Recon Breakpoint folder (the one containing GRB.exe).
    If omitted, common Steam/Ubisoft/Epic locations are searched.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
#>
[CmdletBinding()]
param(
    [string]$GamePath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

function Find-GamePath {
    $candidates = @(
        "C:\Program Files (x86)\Steam\steamapps\common\Ghost Recon Breakpoint",
        "D:\Steam\steamapps\common\Ghost Recon Breakpoint",
        "E:\Steam\steamapps\common\Ghost Recon Breakpoint",
        "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games\Tom Clancy's Ghost Recon Breakpoint",
        "C:\Program Files\Epic Games\Ghost Recon Breakpoint"
    )
    # Parse extra Steam libraries
    $vdf = "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        Select-String -Path $vdf -Pattern '"path"\s+"([^"]+)"' | ForEach-Object {
            $p = ($_.Matches[0].Groups[1].Value -replace '\\\\','\')
            $candidates += (Join-Path $p "steamapps\common\Ghost Recon Breakpoint")
        }
    }
    foreach ($c in $candidates) {
        if (Test-Path (Join-Path $c "GRB.exe")) { return $c }
    }
    return $null
}

if (-not $GamePath) { $GamePath = Find-GamePath }
if (-not $GamePath -or -not (Test-Path (Join-Path $GamePath "GRB.exe"))) {
    throw "Could not locate Ghost Recon Breakpoint. Re-run with -GamePath 'C:\path\to\Ghost Recon Breakpoint'."
}
Write-Host "Game folder: $GamePath" -ForegroundColor Cyan

$shadersRoot = Join-Path $GamePath "reshade-shaders"
$shadersDir  = Join-Path $shadersRoot "Shaders"
$texturesDir = Join-Path $shadersRoot "Textures"
New-Item -ItemType Directory -Force -Path $shadersDir, $texturesDir | Out-Null

if (-not (Test-Path (Join-Path $shadersDir "ReShade.fxh"))) {
    Write-Warning "ReShade.fxh not found. Install the ReShade runtime (DirectX) for GRB.exe FIRST, then re-run this script."
}

function Get-Repo($url, $name) {
    $zip = Join-Path $env:TEMP "$name.zip"
    $out = Join-Path $env:TEMP $name
    Write-Host "Downloading $name ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    if (Test-Path $out) { Remove-Item $out -Recurse -Force }
    Expand-Archive $zip $out -Force
    return (Get-ChildItem $out -Directory | Select-Object -First 1).FullName
}

# --- SweetFX (classic color-grade shaders) ---
$sweet = Get-Repo "https://github.com/CeeJayDK/SweetFX/archive/refs/heads/master.zip" "grb-sweetfx"
$sweetSrc = Join-Path $sweet "Shaders\SweetFX"
$sweetDst = Join-Path $shadersDir "SweetFX"
New-Item -ItemType Directory -Force -Path $sweetDst | Out-Null
Copy-Item "$sweetSrc\*" -Destination $sweetDst -Recurse -Force
Write-Host "  SweetFX installed." -ForegroundColor Green

# --- luluco FXShaders (bloom + lens flare) ---
$lulu = Get-Repo "https://github.com/luluco250/FXShaders/archive/refs/heads/master.zip" "grb-luluco"
$luluDst = Join-Path $shadersDir "luluco"
New-Item -ItemType Directory -Force -Path $luluDst | Out-Null
Copy-Item "$lulu\Shaders\*" -Destination $luluDst -Recurse -Force
if (Test-Path "$lulu\Textures") { Copy-Item "$lulu\Textures\*" -Destination (Join-Path $texturesDir "luluco") -Recurse -Force }
# GrainSpread.fx fails to compile (X4566) and is unused — remove to keep the log clean.
Remove-Item (Join-Path $luluDst "GrainSpread.fx") -Force -ErrorAction SilentlyContinue
Write-Host "  luluco FXShaders installed." -ForegroundColor Green

# --- Copy presets ---
Copy-Item (Join-Path $repoRoot "presets\*.ini") -Destination $GamePath -Force
Write-Host "  Presets copied to game folder." -ForegroundColor Green

# --- Copy any custom LUT textures from repo\luts (*.png) ---
$lutSrc = Join-Path $repoRoot "luts"
$lutPngs = Get-ChildItem $lutSrc -Filter *.png -ErrorAction SilentlyContinue
if ($lutPngs) {
    Copy-Item $lutPngs.FullName -Destination $texturesDir -Force
    Write-Host "  $($lutPngs.Count) LUT texture(s) copied to Textures." -ForegroundColor Green
}

# --- Ensure ReShade.ini search paths + default preset ---
$ini = Join-Path $GamePath "ReShade.ini"
if (Test-Path $ini) {
    $content = Get-Content $ini -Raw
    if ($content -notmatch 'PresetPath=') {
        $content = $content -replace '(\[GENERAL\])', "`$1`r`nPresetPath=.\ReShadePreset.ini"
        Set-Content -Path $ini -Value $content -Encoding ASCII
        Write-Host "  Set default PresetPath in ReShade.ini." -ForegroundColor Green
    }
} else {
    Write-Warning "ReShade.ini not found — install the ReShade runtime (DirectX) first."
}

Write-Host ""
Write-Host "Done. Launch Breakpoint in DirectX mode, press Home, and pick a preset from the dropdown." -ForegroundColor Cyan
