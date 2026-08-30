# Ghost Recon Breakpoint — ReShade Presets

Custom cinematic ReShade presets for **Tom Clancy's Ghost Recon Breakpoint**, plus the
tooling to install them, build new ones, and add custom LUTs.

| Preset | Look |
|--------|------|
| **Cyberpunk 1980s Neon** | Bright neon — teal/blue shadows, magenta-pink highlights, punchy contrast & saturation, subtle chromatic aberration, light grain. |
| **Cinematic — Blade Runner** | Teal-and-amber film grade, softer contrast, slightly desaturated base so neon still *pops* via bloom. Anamorphic-style lens flares + 35mm grain. |

---

## 🚀 Quick start (one line)
Open **PowerShell** and run (edit the path to your game). This downloads the repo, deploys
the shaders + presets, and — if a `ReShade_Setup*.exe` is in your Downloads — launches the
ReShade installer pre-filled:
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/PaulBratslavsky/grb-reshade-presets/main/scripts/bootstrap.ps1))) -GamePath "C:\Program Files (x86)\Steam\steamapps\common\Ghost Recon Breakpoint"
```
Add `-DefaultPreset "Cinematic_BladeRunner.ini"` to pick the starting look, or
`-Api dxgi` (default; use DirectX for Breakpoint). Prefer to do it step-by-step or don't
trust remote scripts? Use the manual setup below.

---

## ⚠️ Important: use the DirectX renderer, not Vulkan
Breakpoint can run on **DirectX** (`GRB.exe`) or **Vulkan** (`GRB_vulkan.exe`).
**ReShade on Vulkan crashes Breakpoint's renderer** (graphics device lost at swapchain
init — confirmed on AMD + HDR). Always install ReShade for **DirectX** and launch the
game in **DirectX mode**. The presets are pure color/post shaders and look identical on
either API, so you lose nothing.

---

## Setup (fresh machine)

### 1. Install the ReShade runtime (one-time, manual)
1. Download ReShade from <https://reshade.me> and run the installer.
2. Select the game executable:
   `...\Ghost Recon Breakpoint\GRB.exe`  ← the **DirectX** exe, not `GRB_vulkan.exe`.
3. Choose rendering API: **DirectX 10/11/12**.
4. Skip the preset step; you can skip/untick the effect packages (this repo's installer
   supplies the shaders). Finish. This drops `dxgi.dll` into the game folder.

### 2. Install shaders + presets (this repo)
```powershell
git clone <this-repo> grb-reshade-presets
cd grb-reshade-presets
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```
The installer will:
- auto-detect the Breakpoint folder (or pass `-GamePath "..."`),
- download the required shader libraries (SweetFX + luluco FXShaders),
- deploy them to `reshade-shaders\`,
- copy the presets into the game folder,
- copy any `luts\*.png` into `Textures\`,
- set the default preset in `ReShade.ini`.

### 3. Play
- Launch Breakpoint and pick **DirectX 11/12** at the API prompt (not Vulkan).
- Press **Home** to open the ReShade overlay.
- Use the **preset dropdown at the top** (with `<` `>` arrows) to switch looks live.

---

## Switching / hot-swapping presets
ReShade has hot-swapping built in — no extra mod needed:
- **Home** menu → preset dropdown at the top → pick a preset. Applies instantly.
- **One-key cycling:** Home → **Settings** tab → set *"Previous preset key"* / *"Next
  preset key"* (e.g. `PgUp` / `PgDn`). Then tap that key in-game to cycle presets without
  opening the menu.

Every `.ini` file in the game folder shows up in the dropdown.

---

## Building new presets
Edit values live in the **Home** menu, then **Save** as a new preset — or author a `.ini`
by hand (see the two in `presets/`). A preset is just:
```
Techniques=Tech1@File1.fx,Tech2@File2.fx,...
TechniqueSorting=... (same list)

[File1.fx]
UniformName=value
```
Then `powershell -File .\scripts\deploy-presets.ps1` to copy repo presets into the game.

**Or ask Claude Code** — this repo ships a skill (`.claude/skills/grb-reshade/`) that knows
the shader palette and can generate a new preset from a described look (e.g. "make a warm
1970s film look" or "cold horror night vibe"). See that skill for the shader reference.

---

## Claude Code skill (build/tune presets by asking)
This repo ships a [Claude Code](https://claude.com/claude-code) skill at
`.claude/skills/grb-reshade/`. It knows the full shader palette, the DirectX-not-Vulkan
gotcha, the recipes, and the deploy scripts — so you can just say *"make a gritty war-film
preset"* or *"set up ReShade for this game"* and it does it.

Install it so it's available in every session:
```powershell
# copy the skill into your personal Claude skills folder
Copy-Item .\.claude\skills\grb-reshade -Destination "$env:USERPROFILE\.claude\skills\" -Recurse -Force
```
Or keep it project-local — Claude Code auto-loads skills from `.claude/skills/` when you run
it inside this repo. Then ask it to set things up or build a new look.

---

## Custom LUTs
Yes — see [`luts/README.md`](luts/README.md). Generate a neutral LUT, grade it in any image
editor, drop the PNG in `luts/`, re-run `install.ps1`, and point `LUT.fx` at it.

---

## Use these looks in other games
The shaders and presets are game-agnostic (pure color/post — no depth-buffer effects), so
they drop into any game that has ReShade. Use the portable installer:
```powershell
# 1. Install the ReShade runtime for the other game's exe (its native API) first.
# 2. Then deploy shaders + presets into that game folder:
powershell -ExecutionPolicy Bypass -File .\scripts\install-anygame.ps1 -GamePath "C:\Games\Cyberpunk 2077"
# optional: set a starting preset
powershell -ExecutionPolicy Bypass -File .\scripts\install-anygame.ps1 -GamePath "D:\...\RDR2" -DefaultPreset "Cinematic_BladeRunner.ini"
```
`-SkipShaders` skips the shader download if they're already present. The presets are tuned
for Breakpoint's lighting, so expect to nudge LiftGammaGain/contrast per game.

**Game-specific auto-detect wrappers** (find the install for you, then call the portable installer):
```powershell
.\scripts\install.ps1              # Ghost Recon Breakpoint (DirectX; never Vulkan)
.\scripts\install-fallout4.ps1     # Fallout 4 (DX11; single-player, no anti-cheat - safe)
.\scripts\install-division2.ps1    # Tom Clancy's The Division 2 (DX11/DX12)
```
The Division 2 is always-online **and runs Easy Anti-Cheat** — injecting ReShade there can
get you banned. Prefer single-player titles (Breakpoint campaign, Fallout 4). Never inject
ReShade into a game protected by EAC / BattlEye / VAC / Vanguard.

> ⚠️ **Anti-cheat:** never use ReShade in multiplayer games protected by BattlEye, EAC, VAC,
> or Vanguard — it can get you banned. Single-player / offline only.

---

## Repo layout
```
presets/                     the custom preset .ini files
luts/                        custom LUT PNGs + how-to (LUT.fx)
scripts/bootstrap.ps1        one-line remote installer (repo + shaders + presets + ReShade)
scripts/install.ps1          Breakpoint installer (auto-detects game, calls installer below)
scripts/install-fallout4.ps1  Fallout 4 installer (auto-detects game)
scripts/install-division2.ps1 The Division 2 installer (auto-detects game)
scripts/install-anygame.ps1  portable installer for ANY game (-GamePath ...)
scripts/deploy-presets.ps1   copy repo presets into the game
scripts/new-neutral-lut.ps1  generate a neutral LUT strip to grade
.claude/skills/grb-reshade/  Claude Code skill to build more presets
```

## Credits / licenses
- Presets and scripts in this repo: MIT (see `LICENSE`).
- [SweetFX](https://github.com/CeeJayDK/SweetFX) by CeeJay.dk — MIT.
- [FXShaders](https://github.com/luluco250/FXShaders) by luluco250 — see repo license.
- Shader libraries are downloaded at install time, not redistributed here.
