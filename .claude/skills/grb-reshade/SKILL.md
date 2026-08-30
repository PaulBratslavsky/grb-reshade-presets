---
name: grb-reshade
description: >
  Set up ReShade for Ghost Recon Breakpoint and build or tune custom ReShade
  presets (color grades, bloom, lens flare, film grain, chromatic aberration,
  LUTs). Use when the user wants a new Breakpoint/GRB ReShade look or preset
  ("make a warm 70s film look", "cold horror preset", "more neon"), wants to
  install/fix ReShade for Breakpoint, hot-swap presets, or add a custom LUT.
---

# Ghost Recon Breakpoint — ReShade setup & preset builder

## Golden rule: DirectX, never Vulkan
Breakpoint has two exes: `GRB.exe` (DirectX) and `GRB_vulkan.exe` (Vulkan).
**ReShade on Vulkan crashes the renderer** (graphics device lost at swapchain init;
`graphicstatedump.txt` shows `GPU: (null)`). Always install ReShade for **`GRB.exe`
/ DirectX 10-11-12** and tell the user to launch in **DirectX mode**. Presets are pure
post shaders and look identical on either API.

If ReShade was mistakenly installed for Vulkan, it registers a global layer at
`C:\ProgramData\ReShade\` with a whitelist `ReShadeApps.ini`. Editing that needs admin
(elevate via `Start-Process ... -Verb RunAs`). Clearing the whitelist (`Apps=`) stops it
crashing the game.

## Key locations (Steam default)
- Game: `C:\Program Files (x86)\Steam\steamapps\common\Ghost Recon Breakpoint\`
- ReShade DX DLL: `<game>\dxgi.dll`
- Config: `<game>\ReShade.ini` (has `PresetPath`, `EffectSearchPaths`, `TextureSearchPaths`)
- Presets: `<game>\*.ini` (each is one look; all appear in the ReShade dropdown)
- Shaders: `<game>\reshade-shaders\Shaders\{SweetFX,luluco,...}`
- Textures/LUTs: `<game>\reshade-shaders\Textures\`
- Log (check for compile errors): `<game>\ReShade.log`

## Deploy / verify
- Install everything (Breakpoint): `scripts\install.ps1` (auto-detects game).
- Install into ANY other game: `scripts\install-anygame.ps1 -GamePath "..." [-DefaultPreset x.ini] [-SkipShaders]`.
- Copy repo presets into game: `scripts\deploy-presets.ps1`.
- After a change, verify no errors: search `ReShade.log` for `| ERROR |`. Unused shaders
  that fail to compile (e.g. `GrainSpread.fx`) are harmless — delete them to clean the log.
  Only shaders referenced by a preset's `Techniques=` line matter.

## Preset file format
```
Techniques=Tech@File.fx,Tech2@File2.fx           ; the enabled effects, in render order
TechniqueSorting=Tech@File.fx,Tech2@File2.fx      ; keep identical to Techniques

[File.fx]
UniformName=value            ; floats as 1.000000 ; float3 as r,g,b ; ints as 0/1/2
```
Only set the uniforms you want to change; the rest use shader defaults. Render order is
top→bottom: **grade → bloom → flare → sharpen → CA → vignette → grain/LUT last-ish**.

## Shader palette & key parameters
Technique name is what goes before the `@`; it is NOT always the filename.

### SweetFX (color grade) — `reshade-shaders\Shaders\SweetFX`
| Technique@File | Purpose | Key uniforms (range) |
|---|---|---|
| `Tonemap@Tonemap.fx` | filmic base | `Gamma`(0-2,1), `Exposure`(-1..1,0), `Saturation`(-1..1,0), `Bleach`(0-1,0), `Defog`(0-1,0), `FogColor`(rgb) |
| `Curves@Curves.fx` | contrast | `Mode`(0 luma/1 chroma), `Formula`(1-11, 4), `Contrast`(-1..1) |
| `LiftGammaGain@LiftGammaGain.fx` | **the color-split grade** | `RGB_Lift`(shadows), `RGB_Gamma`(mids), `RGB_Gain`(highlights); each float3 ~0.5-1.5, 1.0=neutral |
| `Technicolor2@Technicolor2.fx` | rich cinematic color | `ColorStrength`(rgb ~0.2), `Strength`(0-1), `Saturation`, `Brightness` |
| `Vibrance@Vibrance.fx` | smart saturation | `Vibrance`(-1..1), `Vibrance_Luma`(1) |
| `HDR@FakeHDR.fx` | punch/glow | `HDRPower`(~1.1-1.3), `radius1`, `radius2` |
| `LumaSharpen@LumaSharpen.fx` | sharpen | `sharp_strength`(0-3), `sharp_clamp`(0-1) |
| `CA@ChromaticAberration.fx` | color fringe | `Shift`(float2 px), `Strength`(0-1) |
| `Vignette@Vignette.fx` | edge darken | `Amount`(neg darkens, ~-0.3), `Radius`, `Slope`, `Ratio` |
| `FilmGrain@FilmGrain.fx` | grain | `Intensity`(0-1), `Variance`, `Mean`, `SignalToNoiseRatio` |
| `LUT@LUT.fx` | custom LUT | preprocessor `fLUT_TextureName="x.png"`, `fLUT_TileSizeXY`, `fLUT_TileAmount`; uniforms `fLUT_AmountChroma/Luma`(0-1) |
| others available: `DPX`, `Levels`, `Technicolor`, `Tint@Sepia.fx`, `Monochrome`, `Cartoon`, `Border`, `FXAA`, `SMAA` |

### luluco FXShaders (bloom / flare) — `reshade-shaders\Shaders\luluco`
Uses a shared `FXShaders\` include folder — must be copied whole (install.ps1 does this).
| Technique@File | Purpose | Key uniforms |
|---|---|---|
| `NeoBloom@NeoBloom.fx` | cinematic bloom | `Intensity`(0-1), `Saturation`(0-3), `BloomBlendMode`(0 Mix/1 Add/2 Screen), `AdaptAmount`(0 disables auto-exposure), `LensDirtAmount`(0-3) |
| `HexLensFlare@HexLensFlare.fx` | aperture-ghost flares | `uIntensity`(0-3), `uThreshold`(0-1, high=only bright lights), `uScale`(0-10), `uColor0..3`(rgb ghosts) |
| `UnrealLens@UnrealLens.fx` | UE-style bokeh flare | `Brightness`, `Threshold`, `BokehSize`, `Tint` |
| `MagicHDR@MagicHDR.fx` | HDR bloom+tonemap | `BloomAmount`, `BloomBrightness`, `Exposure`, `Tonemap` |
| `ArcaneBloom@ArcaneBloom.fx`, `LiquidLens@LiquidLens.fx` | alt bloom/flare | see in-menu |
> Note: `GrainSpread.fx` fails to compile (X4566) and is unused — keep it deleted.

## Recipes (starting points, then tune live in the Home menu)
- **Neon / cyberpunk:** LiftGammaGain (teal shadows `0.92,1.0,1.18` / magenta highlights
  `1.12,0.96,1.12`) + Vibrance `0.35` + Curves `0.45` + FakeHDR + subtle CA + grain.
- **Cinematic teal-amber (Blade Runner):** Tonemap `Gamma 1.08, Saturation -0.10` +
  LiftGammaGain (teal shadows / amber highlights `1.10,1.02,0.92`) + Curves `0.30` (soft) +
  Vibrance `0.20` + NeoBloom (`Intensity 0.55, Saturation 1.6, Screen`) + HexLensFlare
  (`uIntensity 0.6, uThreshold 0.92`) + grain `0.35`.
- **Warm vintage film:** Tonemap warm FogColor + LiftGammaGain warm across the board +
  Technicolor2 + heavier FilmGrain + strong Vignette; low Vibrance. Consider a LUT.
- **Cold/horror:** LiftGammaGain blue-green everywhere, Curves high contrast, desaturate
  via Tonemap `Saturation -0.3`, Vignette strong, grain.
- **Exact movie look:** build/curate a **LUT** (see `luts/README.md`) + `LUT@LUT.fx` early
  in the order, then a light grain/vignette on top.

## Workflow when the user asks for a new look
1. Pick shaders from the palette; choose sensible values from the recipes.
2. Write `<game>\<Name>.ini` (and mirror it to the repo `presets/` folder).
3. Confirm every referenced shader exists under `reshade-shaders\Shaders\**`; if a needed
   shader is missing, add its library to `install.ps1` and run it.
4. Tell the user to press **Home** → pick the preset from the dropdown, and which 2-3
   uniforms to nudge for taste. Optionally check `ReShade.log` for `| ERROR |`.
