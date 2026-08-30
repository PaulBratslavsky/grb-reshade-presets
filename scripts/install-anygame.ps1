<#
.SYNOPSIS
    Portable installer: deploys the shader libraries and presets from this repo into
    ANY game folder for use with ReShade.

.DESCRIPTION
    Works for any PC game that has the ReShade runtime installed. It downloads the
    required shader libraries (SweetFX + luluco FXShaders), deploys them into
    <GamePath>\reshade-shaders\, copies this repo's presets into the game folder,
    copies any luts\*.png into the Textures folder, and ensures ReShade.ini has the
    correct search paths plus an optional default preset.

    PREREQUISITE: install the ReShade runtime first (https://reshade.me) for the game's
    executable, choosing the game's native rendering API.

.PARAMETER GamePath
    Full path to the game folder that contains the game .exe and ReShade's wrapper DLL.

.PARAMETER SkipShaders
    Do not download or deploy shader libraries (use if already installed for this game).

.PARAMETER DefaultPreset
    Preset file name to set as the active preset in ReShade.ini (default: leave as-is).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\install-anygame.ps1 -GamePath "C:\Games\Cyberpunk 2077"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GamePath,
    [switch]$SkipShaders,
    [string]$DefaultPreset
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path $GamePath)) { throw "GamePath not found: $GamePath" }
Write-Host "Game folder: $GamePath" -ForegroundColor Cyan
$exe = Get-ChildItem $GamePath -Filter *.exe -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($exe) { Write-Host "Detected exe: $($exe.Name)" -ForegroundColor Cyan }

# Sanity: is the ReShade runtime installed in this folder?
$dllPattern = '^(dxgi|d3d9|d3d10|d3d11|d3d12|opengl32|ReShade64|ReShade32)\.dll$'
$reshadeDll = Get-ChildItem $GamePath -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $dllPattern }
$reshadeIni = Join-Path $GamePath 'ReShade.ini'
if (-not $reshadeDll -and -not (Test-Path $reshadeIni)) {
    Write-Warning "No ReShade runtime detected here. Install ReShade for this game first, then re-run. Staging shaders and presets anyway."
}

$shadersRoot = Join-Path $GamePath 'reshade-shaders'
$shadersDir  = Join-Path $shadersRoot 'Shaders'
$texturesDir = Join-Path $shadersRoot 'Textures'
New-Item -ItemType Directory -Force -Path $shadersDir, $texturesDir | Out-Null

function Get-Repo {
    param($url, $name)
    $zip = Join-Path $env:TEMP ($name + '.zip')
    $out = Join-Path $env:TEMP $name
    Write-Host ("Downloading " + $name + " ...") -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    if (Test-Path $out) { Remove-Item $out -Recurse -Force }
    Expand-Archive $zip $out -Force
    return (Get-ChildItem $out -Directory | Select-Object -First 1).FullName
}

if (-not $SkipShaders) {
    $sweet = Get-Repo 'https://github.com/CeeJayDK/SweetFX/archive/refs/heads/master.zip' 'grb-sweetfx'
    $sweetDst = Join-Path $shadersDir 'SweetFX'
    New-Item -ItemType Directory -Force -Path $sweetDst | Out-Null
    Copy-Item (Join-Path $sweet 'Shaders\SweetFX\*') -Destination $sweetDst -Recurse -Force
    Write-Host "  SweetFX installed." -ForegroundColor Green

    $lulu = Get-Repo 'https://github.com/luluco250/FXShaders/archive/refs/heads/master.zip' 'grb-luluco'
    $luluDst = Join-Path $shadersDir 'luluco'
    New-Item -ItemType Directory -Force -Path $luluDst | Out-Null
    Copy-Item (Join-Path $lulu 'Shaders\*') -Destination $luluDst -Recurse -Force
    $luluTex = Join-Path $lulu 'Textures'
    if (Test-Path $luluTex) { Copy-Item (Join-Path $luluTex '*') -Destination (Join-Path $texturesDir 'luluco') -Recurse -Force }
    Remove-Item (Join-Path $luluDst 'GrainSpread.fx') -Force -ErrorAction SilentlyContinue
    Write-Host "  luluco FXShaders installed." -ForegroundColor Green
}

# Copy presets and LUTs
Copy-Item (Join-Path $repoRoot 'presets\*.ini') -Destination $GamePath -Force
Write-Host "  Presets copied to game folder." -ForegroundColor Green
$lutPngs = Get-ChildItem (Join-Path $repoRoot 'luts') -Filter *.png -ErrorAction SilentlyContinue
if ($lutPngs) {
    Copy-Item $lutPngs.FullName -Destination $texturesDir -Force
    Write-Host ("  " + $lutPngs.Count + " LUT texture(s) copied to Textures.") -ForegroundColor Green
}

# Ensure ReShade.ini has search paths and optional default preset
function Set-IniKey {
    param([string]$content, [string]$key, [string]$value)
    $line = ($key + '=' + $value)
    $pat  = ('(?m)^' + [regex]::Escape($key) + '=.*$')
    $nl   = [Environment]::NewLine
    if ($content -match $pat) {
        $eval = [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $line }
        return [System.Text.RegularExpressions.Regex]::Replace($content, $pat, $eval)
    }
    if ($content -match '(?m)^\[GENERAL\]') {
        $evalG = [System.Text.RegularExpressions.MatchEvaluator]{ param($m) ('[GENERAL]' + $nl + $line) }
        return [System.Text.RegularExpressions.Regex]::Replace($content, '(?m)^\[GENERAL\]', $evalG, 1)
    }
    return ('[GENERAL]' + $nl + $line + $nl + $content)
}

if (Test-Path $reshadeIni) {
    $c = Get-Content $reshadeIni -Raw
    $c = Set-IniKey $c 'EffectSearchPaths'  '.\reshade-shaders\Shaders\**'
    $c = Set-IniKey $c 'TextureSearchPaths' '.\reshade-shaders\Textures\**'
    if ($DefaultPreset) { $c = Set-IniKey $c 'PresetPath' ('.\' + $DefaultPreset) }
    Set-Content -Path $reshadeIni -Value $c -Encoding ASCII
    Write-Host "  ReShade.ini search paths ensured." -ForegroundColor Green
} else {
    Write-Warning "ReShade.ini not present yet. It is created on first run with ReShade; re-run with -SkipShaders afterwards to set a default preset."
}

Write-Host ""
Write-Host "Done. Launch the game, press Home, and pick a preset from the ReShade dropdown." -ForegroundColor Cyan
Write-Host "Notes:" -ForegroundColor Yellow
Write-Host "  * Install ReShade for the game native API (usually DirectX). Vulkan is fine for most" -ForegroundColor Yellow
Write-Host "    games; it only crashed Ghost Recon Breakpoint specifically." -ForegroundColor Yellow
Write-Host "  * Presets are tuned for Breakpoint lighting - expect to nudge LiftGammaGain/contrast." -ForegroundColor Yellow
Write-Host "  * Do NOT use ReShade in multiplayer games with anti-cheat (BattlEye/EAC/VAC/Vanguard);" -ForegroundColor Yellow
Write-Host "    it can get you banned. Single-player / offline only." -ForegroundColor Yellow
