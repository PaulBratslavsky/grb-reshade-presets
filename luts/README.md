# Custom LUTs

A **LUT** (Look-Up Table) bakes an entire color grade into a single image. It's the
fastest way to reproduce a specific film/movie look exactly, and it's cheap to render.
ReShade applies LUTs with the built-in **`LUT.fx`** shader (already installed).

## How a ReShade LUT works
A LUT is a horizontal strip PNG. The default layout is **1024×32** = 32 tiles of 32×32,
where each tile is a slice of the blue axis and X/Y within a tile are red/green. A
*neutral* LUT (identity) changes nothing; you grade it to create a look.

## Make your own custom LUT
1. **Generate a neutral LUT:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File ..\scripts\new-neutral-lut.ps1
   ```
   → creates `neutral-lut.png` in this folder.
2. **Grade it.** Open a copy in Photoshop / GIMP / Affinity / DaVinci and apply your
   color grade to the *whole strip* (curves, color balance, LUT from a film still,
   Camera Raw, etc.). Non-destructive, global adjustments only — don't paint locally
   or blur. Save as e.g. `blade-runner-lut.png` here.
   - Pro tip: take an in-game screenshot, paste the neutral strip into a corner, grade
     the screenshot until it looks right, then copy those same adjustment layers onto
     the strip and export just the strip.
3. **Deploy:** run `..\scripts\install.ps1` (copies every `luts\*.png` into the game's
   `reshade-shaders\Textures\` folder).
4. **Enable in a preset / in-game:**
   - In the ReShade **Home** menu, enable **LUT.fx**.
   - Expand it → **Edit** the preprocessor definition:
     `fLUT_TextureName = "blade-runner-lut.png"`
   - If you used a 64px tile strip, also set `fLUT_TileSizeXY = 64` and `fLUT_TileAmount = 64`.
   - `fLUT_AmountChroma` / `fLUT_AmountLuma` (0–1) control how strongly the LUT is mixed in.

## Using a LUT inside a repo preset
Add `LUT@LUT.fx` to the `Techniques=` line and set the preprocessor in the preset's
`PreprocessorDefinitions=` line, e.g.:
```
PreprocessorDefinitions=fLUT_TextureName="blade-runner-lut.png",fLUT_TileSizeXY=32,fLUT_TileAmount=32
```
Put a LUT **early** in the technique order (right after the base grade, before bloom/grain)
so effects layer on top of the graded image.

## Where to get ready-made LUTs
Any standard `.png` LUT strip works (many free "CUBE→PNG" film LUT packs exist). Convert
`.cube` LUTs to a PNG strip with tools like *IWLTBAP LUT tools* or an online cube-to-PNG
converter, then drop the PNG here.

> Drop any `*.png` LUT files in this folder and they'll be deployed by `install.ps1`.
