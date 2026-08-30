<#
.SYNOPSIS
    Generates a NEUTRAL LUT strip PNG for ReShade's LUT.fx (default 1024x32 layout:
    32 tiles of 32x32). A neutral LUT changes nothing until you grade it.

.DESCRIPTION
    Workflow for a custom LUT:
      1. Run this to create luts\neutral-lut.png.
      2. Take an in-game SCREENSHOT that also contains this LUT strip overlaid,
         OR just open the neutral LUT in Photoshop/GIMP/DaVinci and apply your
         color grade (curves, color balance, etc.) to the WHOLE strip.
      3. Save the graded strip as luts\my-look.png.
      4. Run scripts\install.ps1 (copies luts\*.png into the game Textures folder),
         then enable LUT.fx in your preset with:
            preprocessor  fLUT_TextureName = "my-look.png"
         (Set this in the ReShade Home menu -> LUT.fx -> Edit, or in the preset's
          PreprocessorDefinitions line.)

.PARAMETER TileSize
    Pixels per tile (default 32 -> 1024x32 strip). Use 64 for a higher-quality
    64x64 -> 4096x64 strip (set fLUT_TileSizeXY=64, fLUT_TileAmount=64 in LUT.fx).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\new-neutral-lut.ps1
#>
[CmdletBinding()]
param(
    [int]$TileSize = 32,
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutFile) { $OutFile = Join-Path $repoRoot "luts\neutral-lut.png" }

$tiles  = $TileSize            # number of blue slices == tile count
$width  = $TileSize * $tiles
$height = $TileSize
$max    = $TileSize - 1

$bmp = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($x = 0; $x -lt $width; $x++) {
    $b = [int]([math]::Floor($x / $TileSize))   # blue = which tile
    $r = $x % $TileSize                          # red   = column within tile
    for ($y = 0; $y -lt $height; $y++) {
        $g = $y                                  # green = row
        $cr = [int][math]::Round($r * 255.0 / $max)
        $cg = [int][math]::Round($g * 255.0 / $max)
        $cb = [int][math]::Round($b * 255.0 / $max)
        $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $cr, $cg, $cb))
    }
}
New-Item -ItemType Directory -Force -Path (Split-Path $OutFile) | Out-Null
$bmp.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Neutral LUT written: $OutFile  ($width x $height, tile=$TileSize)" -ForegroundColor Green
Write-Host "Grade a copy of it in an image editor, save as luts\<name>.png, then re-run install.ps1." -ForegroundColor Cyan
