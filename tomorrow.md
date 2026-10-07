# Liquid Glass — Tomorrow's Work Spec

> **Purpose:** Actionable task list for spawning agents. Each task includes context, acceptance criteria, and implementation hints so an agent can pick it up and execute with minimal back-and-forth.

---

## Project Context (Read Once)

**What this is:** A Rainmeter skin (`LiquidGlass.ini`) that displays a frosted-glass desktop panel showing:
- Clock/date
- Weather (from HA `weather.forecast_home`)
- 4 lights (toggle via HA REST API)
- 4 media players (play/pause via HA REST API)

**Tech stack:**
- Rainmeter 4.5+ (INI config + Shape meters + JScript measures)
- Home Assistant REST API via `HomeAssitantPlugin.dll` (reads) + `ha-control.js` (writes via `cscript.exe`)
- All config in `@Resources/Settings.inc` (gitignored; `.example` tracked)

**Key files:**
| File | Role |
|------|------|
| `LiquidGlass.ini` | Main skin (1309 lines — measures + meters) |
| `@Resources/Settings.inc` | HA connection, entity IDs, labels, units |
| `@Resources/ha-control.js` | JScript helper: `cscript.exe //NoLogo ha-control.js <entity> <service>` |
| `@Resources/wxcond.js` | Weather condition parser (currently stub) |
| `scripts/validate-skin.ps1` | Lint/validation script |

**HA Connection:**
- Server: `192.168.4.110:8123` (HTTP, token in Settings.inc)
- Primary entities defined in `[Variables]` section of `LiquidGlass.ini` (lines 2-17, 75-77)

---

## Task List

### T1 — Move % label below temperature, add "HUMIDITY" label
**Priority:** HIGH | **Effort:** Small

**Current state:** Humidity meter (`[MeterWxHum]` at line 969-979) sits top-right of temp value.

**Desired:**
```
[Large Temp]          [HUMIDITY]
                       [XX%]
```

**Files to edit:** `LiquidGlass.ini`
- Move `[MeterWxHum]` Y position below `[MeterWxTemp]` (currently Y=210 → ~Y=245)
- Add a new label meter `[MeterWxHumLabel]` above it: "HUMIDITY", muted color, FontSize=10, FontWeight=600
- Keep StringAlign=RightTop on both
- Update `[MeterWxCond]` Y if needed (currently 248) to avoid overlap

**Acceptance:**
- Visual: humidity % sits under temp with "HUMIDITY" label above it
- No overlap with condition text
- `validate-skin.ps1` passes

---

### T2 — Install WebParse plugin, bundle it, fix weather condition text
**Priority:** HIGH | **Effort:** Medium

**Problem:** Weather condition (`MeasureWxState` → `attributes.condition`) returns cryptic codes like `clear-night`, `partlycloudy`. Need human-readable text (e.g., "Clear", "Partly Cloudy").

**Current stub:** `@Resources/wxcond.js` only echoes "TEST".

**Solution:** Use Rainmeter's `WebParser` plugin (built-in) to fetch condition from HA REST API, then map codes in a JScript measure. **Do not** add external DLLs — WebParser is native.

**Implementation:**
1. Add a `WebParser` measure hitting `http://192.168.4.110:8123/api/states/weather.forecast_home` with auth header
2. Extract `attributes.condition` via `RegExp`
3. Create a Script measure (`[MeasureWxCondMapped]`) that maps HA condition codes → display strings (see mapping below)
4. Update `[MeterWxCond]` to use `MeasureName=MeasureWxCondMapped`
5. Remove the duplicate/conflicting `[MeterWxCond]` meters (lines 981-1025 — there are 3 overlapping definitions)

**HA Condition Code Mapping:**
```javascript
const MAP = {
  "clear-night": "Clear Night",
  "cloudy": "Cloudy",
  "fog": "Fog",
  "hail": "Hail",
  "lightning": "Thunderstorm",
  "lightning-rainy": "Thunderstorm",
  "partlycloudy": "Partly Cloudy",
  "pouring": "Pouring",
  "rainy": "Rain",
  "snowy": "Snow",
  "snowy-rainy": "Rain/Snow",
  "sunny": "Sunny",
  "windy": "Windy",
  "windy-variant": "Windy",
  "exceptional": "Extreme"
};
```

**Files to edit:** `LiquidGlass.ini`, `@Resources/wxcond.js` (replace stub)

**Acceptance:**
- Weather condition shows human-readable text (e.g., "Partly Cloudy")
- No duplicate meter definitions
- Works offline gracefully (shows "—" or empty)
- `validate-skin.ps1` passes

---

### T3 — Push changes to git
**Priority:** LOW | **Effort:** Trivial

**Action:** `git add -A && git commit -m "..." && git push`

**Note:** Only after T1-T2 are verified. Include `.gitignore` check (`.qa-tmp/` already ignored per LIQUIDGLASS-012).

---

### T4 — Add media controls to streaming section
**Priority:** MEDIUM | **Effort:** Medium

**Current:** Media tiles only show state + play/pause toggle on click.

**Desired:** Add prev/next/volume controls per media tile (or a shared control bar).

**Options:**
- **A (minimal):** Add prev/next buttons inside each media tile (small icons)
- **B (shared):** Add a persistent control bar below media section with prev/play/next + volume slider for the *active* player

**Implementation (Option A recommended):**
- For each media tile, add 2 small Shape meters (◀ ▶) with `LeftMouseUpAction` calling `ha-control.js` with `media_player.media_previous_track` / `media_player.media_next_track`
- Add volume up/down if space permits (or skip for v1)
- Update `ha-control.js` to accept optional 3rd arg for service data (volume level)

**Files to edit:** `LiquidGlass.ini`, `@Resources/ha-control.js`

**Acceptance:**
- Prev/next work on at least one media player
- Click targets are large enough (≥20px)
- No layout breakage

---

### T5 — Add color selection + brightness % control for supported lights
**Priority:** MEDIUM | **Effort:** Large

**Current:** Lights only toggle on/off.

**Target entities that support color/brightness:**
- `light.living_room_brodie_s_lightstrip` (RGB + brightness)
- `light.living_room_living_room_lamp` (brightness)
- `light.bedroom_bedroom_lamp` (brightness)

**Desired UI:**
- Click light tile → expands/shows a control overlay with:
  - Brightness slider (0-100%)
  - Color picker (for RGB lights) — can be preset swatches
- Or: Long-press / right-click opens control panel

**Implementation approach:**
1. Add measures to read `attributes.brightness` (0-255) and `attributes.rgb_color` / `attributes.hs_color`
2. Add hidden overlay meters (Shape + String) per light — initially `Hidden=1`
3. On left-click: toggle overlay visibility
4. Overlay buttons call `ha-control.js` with `light.turn_on` + JSON payload: `{"entity_id": "...", "brightness": 128, "rgb_color": [255,0,0]}`
5. Update `ha-control.js` to send POST body with full service data (not just entity_id)

**Files to edit:** `LiquidGlass.ini`, `@Resources/ha-control.js`, `@Resources/Settings.inc` (add entity IDs for brightness/color attributes)

**Acceptance:**
- Brightness slider works on all 3 dimmable lights
- Color picker works on lightstrip
- State updates reflect within ~3s (UpdateDivider=3)
- No performance regression

---

### T6 — Allow 12-hour and 24-hour time formats
**Priority:** LOW | **Effort:** Small

**Current:** `[MeasureTime]` uses `Format=%H:%M` (24h hardcoded).

**Desired:** Setting in `Settings.inc` → `TIME_FORMAT=12` or `24`.

**Implementation:**
- Add `TIME_FORMAT=24` to `Settings.inc` `[Variables]`
- In `LiquidGlass.ini`, use conditional: `Format=%#I:%M %p` for 12h, `%H:%M` for 24h
- Rainmeter doesn't support inline conditionals in Measure Format → use two measures + Calc or Script measure to pick

**Simpler approach:** Two measures, one hidden:
```
[MeasureTime24] Measure=Time Format=%H:%M
[MeasureTime12] Measure=Time Format=%#I:%M %p
[MeasureTime] Measure=Calc Formula=(#TIME_FORMAT#=12 ? MeasureTime12 : MeasureTime24)  -- not valid
```
Better: Use a Script measure that reads `#TIME_FORMAT#` and returns formatted string.

**Files to edit:** `LiquidGlass.ini`, `@Resources/Settings.inc`

**Acceptance:**
- Switching `TIME_FORMAT` in Settings.inc + refresh toggles format
- 12h shows "3:45 PM", 24h shows "15:45"

---

### T7 — Allow °C and °F temperature units
**Priority:** LOW | **Effort:** Small

**Current:** `UNIT_TEMP=F` hardcoded in `LiquidGlass.ini` line 16. Display just appends "F".

**Desired:** `UNIT_TEMP=C` or `F` in `Settings.inc`. Convert HA temperature (always °C) on display.

**HA returns:** Temperature in °C (metric) regardless of HA user prefs.

**Implementation:**
- Add `UNIT_TEMP=F` to `Settings.inc`
- Create `[MeasureWxTempDisplay]` Script measure:
  - Reads `MeasureWxTemp` (value in °C)
  - If `UNIT_TEMP=F`: return `Round(value * 9/5 + 32) + "°F"`
  - Else: return `Round(value) + "°C"`
- Update `[MeterWxTemp]` to use `MeasureName=MeasureWxTempDisplay`
- Remove hardcoded `#UNIT_TEMP#` from meter Text

**Files to edit:** `LiquidGlass.ini`, `@Resources/Settings.inc`

**Acceptance:**
- `UNIT_TEMP=C` shows "22°C", `UNIT_TEMP=F` shows "72°F"
- Conversion is accurate (±1°)
- High/low temps (when implemented) also convert

---

### T8 — Fix the glass panel visual
**Priority:** MEDIUM | **Effort:** Medium

**Problem:** "Fix the glass" — likely refers to:
1. Panel background (`[MeterPanel]` lines 871-876) — current shape is basic rectangles
2. Frosted glass effect — currently just solid color + noise texture
3. Edge glints / diagonal sheen — defined but may not render correctly

**Desired:** True frosted glass look:
- Semi-transparent background with blur (Rainmeter can't do real blur)
- Workaround: Screenshot desktop, blur externally, save as `wallpaper-blur.png` in `@Resources`, enable `[MeterWallpaper]` (currently commented lines 858-868)
- Or: Layer multiple semi-transparent gradients to simulate depth

**Quick win (no external deps):**
- Enhance `[MeterPanel]` with more gradient layers
- Add subtle inner shadow (dark overlay at top/left, light at bottom/right)
- Ensure `noise.png` tiles correctly (ImageAlpha=80 may be too strong → 40-50)

**Files to edit:** `LiquidGlass.ini` (meters 871-887), optionally add `wallpaper-blur.png`

**Acceptance:**
- Panel looks like frosted glass (depth, not flat)
- No performance hit
- Works at 380×624

---

### T9 — Diagnose & fix performance drain / errors
**Priority:** HIGH | **Effort:** Large (investigation)

**Symptoms:** "Running the widget is draining performance (there are errors to look at)"

**Likely causes:**
1. **Too many measures:** 80+ Plugin measures polling HA every 3-10s → HTTP storm
2. **Sync XHR in ha-control.js** — blocks Rainmeter on click (10s timeout)
3. **UpdateDivider too aggressive** — many at 3s (20 req/s)
4. **Duplicate measures/meters** — e.g., 3x `[MeterWxCond]` definitions
5. **No error handling** — failed requests retry immediately

**Investigation steps:**
1. Run skin, open Rainmeter Log (Debug mode) → capture errors
2. Count active measures: `grep -c "Measure=Plugin" LiquidGlass.ini` → ~85
3. Check `UpdateDivider` distribution — consolidate to 10s default, 5s for interactive (lights/media), 30s for static (sun, backup sensors)
4. Add `IfCondition` to skip measures when entity unavailable
5. Consider: group HA calls via single WebParser measure + JSON parse in Script (reduces 80 HTTP → 1)

**Quick fixes (do first):**
- Remove duplicate `[MeterWxCond]` meters (lines 981-1025)
- Consolidate `UpdateDivider`: weather 30s, lights/media 5s, sun/backup 60s
- Add `Disabled=1` to unused entity measures (many defined but not displayed)
- Fix `ha-control.js` timeout (already 10s but sync — consider async via `WScript.Shell` Run)

**Files to edit:** `LiquidGlass.ini`, `@Resources/ha-control.js`, `@Resources/Settings.inc`

**Acceptance:**
- Rainmeter CPU < 2% idle (currently likely 5-10%+)
- No errors in Rainmeter log after 5 min
- Skin loads in < 2s
- All displayed entities still update

---

## Execution Order (Dependencies)

```
T1 ──┐
T2 ──┤──→ T3 (push)
T8 ──┘
T9 ──────────────────→ (do early, informs others)
T4, T5, T6, T7 ──────→ (independent, can parallelize)
```

**Recommended first session:** T9 (diagnose) → T1 → T2 → T8 → T3 → then T4/T5/T6/T7 in any order.

---

## Agent Handoff Notes

- **Read first:** `LiquidGlass.ini`, `STRUCTURE.md`, `@Resources/Settings.inc`, `@Resources/ha-control.js`
- **Validation:** Always run `scripts/validate-skin.ps1` after edits
- **Testing:** Refresh skin in Rainmeter (`!RefreshApp` or right-click → Refresh)
- **Debug:** Rainmeter → Manage → Log → Debug mode
- **HA API:** Use `HARESTAPI.md` link for REST endpoints
- **Don't:** Rewrite entire file, add external deps, change architecture
- **Do:** Extend existing patterns, reuse `ha-control.js` for new actions, keep measures grouped by section