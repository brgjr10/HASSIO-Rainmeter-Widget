# Liquid Glass — Memory Bank

## Debugging history

### Shape rendering failures
- **Symptom:** `LinearGradient has invalid parameters`
- **Cause:** Rainmeter 4.5 Shape meters do not support `LinearGradient` syntax
- **Fix:** Replace gradient fills with solid `Fill Color R,G,B`

- **Symptom:** `Fill has invalid parameters: 22,27,34,204`
- **Cause:** Shape `Fill`/`Stroke` were being parsed as `R,G,B,A` with float alpha
- **Fix:** Use `Fill Color R,G,B` / `Stroke Color R,G,B` and remove alpha from color tuples

- **Symptom:** `Invalid shape: Polygon 0,0`
- **Cause:** `Polygon` shape type not valid in this build
- **Fix:** Remove `Polygon` sheen shapes; keep `Rectangle` and `Ellipse` only

### Plugin measure crashes
- **Symptom:** `Object reference not set to an instance of an object` on `MeasureWxHi`/`MeasureWxLo`
- **Cause:** `attributes.forecast.0.temperature` path returns null for the weather entity
- **Fix:** Comment out both measures; show `--` placeholders in `MeterWxHiLo`

- **Symptom:** `Input string was not in a correct format` on kiosk brightness/volume
- **Cause:** `isInt=true` forced numeric parse on non-numeric sensor strings
- **Fix:** Remove `isInt=true` from `[MeasureSensorIpadKioskBrightness]` and `[MeasureSensorIpadKioskVolume]`

### File corruption / duplicate layout
- **Symptom:** Overlapping meters, invisible widget
- **Cause:** Two partial designs stacked in one file (lines 1272–1553 were a duplicate block)
- **Fix:** Delete duplicate section; keep single clean layout

### Variable resolution
- **Symptom:** Variables not resolving in meters
- **Cause:** UTF-8 BOM in `Settings.inc`; LF line endings in `LiquidGlass.ini`
- **Fix:** Remove BOM; convert `LiquidGlass.ini` to CRLF

### Weather layout overlap
- **Symptom:** Weather icon and temperature text overlapped vertically (both bottom-aligned at ~Y=226)
- **Symptom:** Condition text and temperature collided when icon text fell back to raw state string
- **Fix:** Repositioned icon to Y=188 / FontSize=40, temp to Y=160 / FontSize=52 / X=120, condition to Y=240 / FontSize=13. This ensures no overlap even if emoji substitute fails and raw text displays.

### Broken high/low placeholder
- **Symptom:** `MeterWxHiLo` showed `H --°F  L --°F` because forecast measures are commented out
- **Fix:** Replaced with clean `High --   Low --` placeholder without broken unit suffix

### Device control
- **Added:** `@Resources/ha-control.js` — JScript helper using `Microsoft.XMLHTTP` to call HA REST API (`light.toggle`, `media_player.media_play_pause`) with Bearer token auth
- **Added:** `LeftMouseUpAction` to all light tiles (String Lights, Lightstrip, Living Room Lamp, Bedroom Lamp) calling `light.toggle`
- **Added:** `LeftMouseUpAction` to all media tiles (Brodie TV 2, Brodie TV, Home Display, Home Speaker) calling `media_player.media_play_pause`
- **Result:** Clicking any device tile now toggles it in Home Assistant
- **Note:** Uses `cscript.exe //NoLogo` to avoid execution-policy issues that broke the previous PowerShell implementation

## Known issues

- `MeasureNumberLivingRoomBrodieSLightstripEffectSpeed` occasionally logs `One or more errors occurred`
- Weather high/low forecast is disabled because the weather entity's forecast path is null
- Kiosk brightness/volume measures now return raw strings; no numeric parsing
- Device control requires the HA server to be reachable; JScript errors are silenced

## Lessons learned

- Rainmeter 4.5 Shape syntax:
  - Use `Fill Color R,G,B` and `Stroke Color R,G,B`
  - No `LinearGradient`, no `Polygon`, no float alpha in color tuples
  - `FontColor` still supports `R,G,B,A` with alpha
- Home Assistant weather entity may not expose `forecast.0.temperature` depending on configuration
- Plugin measures with `isInt=true` will crash if the state value is non-numeric

## Future improvements

- Add brightness/volume sliders using `[Measure*]` with `LeftMouseUpAction`
- Replace hardcoded weather placeholders with working forecast paths when available
- Add `wallpaper-blur.png` support for true frosted-glass effect
- Consider splitting entity measures into separate include files for maintainability
