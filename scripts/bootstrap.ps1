<#
.SYNOPSIS
    One-line bootstrap. Downloads this repo and deploys the ReShade shaders + presets into
    a game - and optionally launches the ReShade runtime installer pre-filled.

.DESCRIPTION
    Run straight from GitHub (no git clone needed):

      & ([scriptblock]::Create((irm https://raw.githubusercontent.com/PaulBratslavsky/grb-reshade-presets/main/scripts/bootstrap.ps1))) -GamePath "C:\Program Files (x86)\Steam\steamapps\common\Ghost Recon Breakpoint"

    Steps: download repo zip -> extract -> (optionally run ReShade setup pre-filled) ->
    run install-anygame.ps1 to deploy shaders + presets + LUTs.

.PARAMETER GamePath
    Game folder that contains the game .exe. Required.

.PARAMETER Api
    Rendering API for the ReShade installer step. dxgi = DirectX 10/11/12 (default).
    NOTE: for Ghost Recon Breakpoint use dxgi (DirectX) - Vulkan crashes it.

.PARAMETER DefaultPreset
    Preset file to set as the active preset (e.g. Cinematic_BladeRunner.ini).

.PARAMETER ReShadeSetup
    Path to ReShade_Setup_x.x.x.exe. Auto-searched in your Downloads folder if omitted.

.PARAMETER Ref
    Repo branch or tag to fetch (default: main).
#>
param(
    [Parameter(Mandatory = $true)][string]$GamePath,
    [ValidateSet('dxgi','d3d9','opengl','vulkan')][string]$Api = 'dxgi',
    [string]$DefaultPreset,
    [string]$ReShadeSetup,
    [string]$Ref = 'main'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $GamePath)) { throw "GamePath not found: $GamePath" }

# 1. Download the repo (no git required)
$zip = Join-Path $env:TEMP 'grb-reshade-presets.zip'
$dst = Join-Path $env:TEMP 'grb-reshade-presets-src'
$url = "https://github.com/PaulBratslavsky/grb-reshade-presets/archive/refs/heads/$Ref.zip"
Write-Host "Downloading repo ($Ref) ..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
Expand-Archive $zip $dst -Force
$repo = (Get-ChildItem $dst -Directory | Select-Object -First 1).FullName

# 2. ReShade runtime: install it if missing (pre-fill the installer with the exe + API)
$exe = Get-ChildItem $GamePath -Filter *.exe -File -ErrorAction SilentlyContinue | Select-Object -First 1
$hasReShade = Get-ChildItem $GamePath -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^(dxgi|d3d9|d3d10|d3d11|d3d12|opengl32)\.dll$' }
if (-not $hasReShade) {
    if (-not $ReShadeSetup) {
        $ReShadeSetup = (Get-ChildItem "$env:USERPROFILE\Downloads" -Filter 'ReShade_Setup*.exe' -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
    }
    if ($ReShadeSetup -and $exe) {
        Write-Host "Launching ReShade installer for $($exe.Name) (choose DirectX / effects if prompted) ..." -ForegroundColor Cyan
        Start-Process $ReShadeSetup -ArgumentList "`"$($exe.FullName)`"", '--api', $Api
        Read-Host "When the ReShade install finishes, press Enter to continue"
    } else {
        Write-Warning "No ReShade runtime here and no ReShade_Setup*.exe found. Install ReShade from https://reshade.me for '$($exe.Name)' (DirectX), then re-run this."
    }
}

# 3. Deploy shaders + presets + LUTs
$p = @{ GamePath = $GamePath }
if ($DefaultPreset) { $p.DefaultPreset = $DefaultPreset }
& (Join-Path $repo 'scripts\install-anygame.ps1') @p

Write-Host ""
Write-Host "Bootstrap complete. Launch the game (DirectX mode), press Home, pick a preset." -ForegroundColor Green
