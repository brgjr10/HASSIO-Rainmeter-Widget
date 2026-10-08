# Adversarial Code Review — HASSIO-Rainmeter-Widget (LiquidGlass)

**Review Date:** 2026-10-06
**Reviewer:** Adversarial Code Review Agent
**Baseline Commit:** a6bbcc7
**Diff Reviewed:** Working tree changes (unstaged)

---

## Executive Summary

**Status: READY TO MERGE** — 14 of 16 findings addressed correctly (including 2 new fixes), 2 LOW findings unaddressed (deferred by owner), 1 INFO finding addressed. No blocking regressions introduced. Two previously identified issues (LIQUIDGLASS-013, LIQUIDGLASS-014) remain unfixed per owner decision. One minor gap in JSON escaping completeness (LIQUIDGLASS-010 partial).

---

## Fix Verification Matrix

| Finding | Severity | Description | Fixed? | Complete? | Notes |
|---------|----------|-------------|--------|-----------|-------|
| LIQUIDGLASS-001 | HIGH | `isInt=true` crash on 4 measures (temp, humidity, battery, effect speed) | **Y** | **Y** | Removed from all 4 measures (lines 55, 91, 448, 549 in original) |
| LIQUIDGLASS-002 | HIGH | `ha-control.js` no error handling — unhandled runtime error | **Y** | **Y** | Wrapped in try/catch; checks `xhr.status`; `WScript.Quit(1)` on failure |
| LIQUIDGLASS-003 | MEDIUM | Synchronous XHR with no timeout | **Y** | **Y** | Switched to `MSXML2.ServerXMLHTTP.6.0` + `setTimeouts(10000,10000,10000,10000)` |
| LIQUIDGLASS-004 | MEDIUM | Hardcoded HTTP — no HTTPS support | **Y** | **Y** | `MSXML2.ServerXMLHTTP.6.0` supports HTTPS; scheme configurable via `HA_SSL` |
| LIQUIDGLASS-005 | MEDIUM | Light meters map "unavailable" → "Off" (confusable with "OFF") | **Y** | **Y** | Changed to `"unavailable":"Unavailable"` on all 4 light meters |
| LIQUIDGLASS-006 | LOW | `MeasureSensorPct` defined but never referenced | **Y** | **Y** | Measure completely removed |
| LIQUIDGLASS-007 | LOW | `UNIT_TEMP` duplicated with conflicting values (F vs °F) | **Y** | **Y** | Removed `UNIT_TEMP=F` from ini `[Variables]`; now sourced from Settings.inc (°F) |
| LIQUIDGLASS-015 | LOW | No humidity display — `MeasureWxHum` measure exists but no meter | **Y** | **Y** | Added `[MeterWxHum]` at line 971, validation pass |
| LIQUIDGLASS-016 | LOW | `validate-skin.ps1` incorrectly flags valid `UNIT_TEMP=F` config | **Y** | **Y** | Check 5 now validates exactly one occurrence |
| LIQUIDGLASS-008 | LOW | Media meters don't handle "unavailable" state | **Y** | **Y** | Added `"unavailable":"Unavailable"` to all 4 media state meters |
| LIQUIDGLASS-009 | LOW | `ha-control.ps1.example` dead code | **Y** | **Y** | File deleted |
| LIQUIDGLASS-010 | LOW | `entityId` concatenated into JSON without escaping | **Y** | **PARTIAL** | `escapeJson()` added but incomplete — misses `\b`, `\f`, unicode (`\uXXXX`) |
| LIQUIDGLASS-011 | LOW | `ha-control.ps1.example` silent fail | **Y** | **Y** | Dead code deleted (fix via LIQUIDGLASS-009) |
| LIQUIDGLASS-012 | LOW | `.qa-tmp/` not in `.gitignore` | **Y** | **Y** | Added `.qa-tmp/` to `.gitignore` |
| LIQUIDGLASS-013 | LOW | `MeterWxCond` weather Substitute has no catch-all for unknown states | **N** | **N** | Unchanged — raw unknown states still display |
| LIQUIDGLASS-014 | LOW | `MeterDot` HA status indicator always green | **N** | **N** | Unchanged — static green shape, no dynamic binding |
| LIQUIDGLASS-INFO-001 | INFO | Unused variables in `Settings.inc.example` | **Y** | **Y** | Removed `LIGHT_LABEL`, `PRESENCE_LABEL`, `SENSOR_LABEL`, `PLUGIN_PATH` |

---

## BLOCKING Defects

**None.** All HIGH and MEDIUM findings from the QA report have been correctly resolved. No regressions introduced that break existing functionality.

---

## NON-BLOCKING Issues

### 1. LIQUIDGLASS-010 Partial Fix — Incomplete JSON Escaping
**File:** `@Resources/ha-control.js.example:16-23`
```javascript
function escapeJson(str) {
    str = str.replace(/\\/g, "\\\\");
    str = str.replace(/"/g, "\\\"");
    str = str.replace(/\n/g, "\\n");
    str = str.replace(/\r/g, "\\r");
    str = str.replace(/\t/g, "\\t");
    return str;
}
```
**Issue:** Missing escapes for:
- Backspace (`\b` → `\\b`)
- Form feed (`\f` → `\\f`)
- Unicode characters (would need `\uXXXX` encoding)
**Impact:** LOW — Entity IDs follow `domain.object_id` pattern (alphanumeric + underscore), so exploitation unlikely. However, a malformed entity ID containing `\b` or `\f` would produce invalid JSON.
**Recommendation:** Extend `escapeJson` to handle all JSON control characters, or document the entity ID constraint.

### 2. LIQUIDGLASS-013 Unfixed — Weather Condition No Catch-All
**File:** `LiquidGlass.ini:890`
**Issue:** `Substitute` chain maps known HA weather states but has no fallback. Unknown/custom states display as raw slug.
**Impact:** LOW — Cosmetic only. New HA weather conditions or custom components would show lowercase slug (e.g., `foggy` instead of `Foggy`).
**Recommendation:** Add a fallback meter or document as accepted limitation.

### 3. LIQUIDGLASS-014 Unfixed — MeterDot Static Green
**File:** `LiquidGlass.ini:819-822`
**Issue:** `[MeterDot]` is a static `Shape` meter with hardcoded green fill. No `MeasureName`, no dynamic color binding, no HA availability measure exists.
**Impact:** LOW — User sees green "connected" indicator even when HA is unreachable (all entities show "Unavailable").
**Recommendation:** Add a connection-status measure (e.g., ping HA API or monitor a core entity) and bind `Fill Color` via `DynamicVariables=1` + `IfCondition`.

### 4. Remaining `isInt=true` on Other Measures (Not in Original Findings)
**File:** `LiquidGlass.ini:145, 462, 749`
| Line | Measure | Path | Risk |
|------|---------|------|------|
| 145 | `MeasureClimateBright` | `attributes.brightness` | LOW — HA climate brightness typically 0-255 integer |
| 462 | `MeasureSelectSmartPlugPowerOnBehavior` | `state` (SELECT entity) | **MEDIUM** — Select entities return string option, NOT integer |
| 749 | `MeasureTodoShoppingList` | `state` (TODO entity) | LOW — Typically integer count, but could be string |

**Note:** The QA report only flagged 4 specific measures documented in `BANK.md`. The select entity at line 462 is a latent crash risk (string state → `isInt=true` parse failure). Not a regression, but a pre-existing issue not in scope.

---

## Regression Check

| Area | Status | Evidence |
|------|--------|----------|
| `ha-control.js` error handling | ✅ Improved | Try/catch + status check + non-zero exit |
| `ha-control.js` timeout | ✅ Fixed | `setTimeouts(10000,10000,10000,10000)` on ServerXMLHTTP |
| `ha-control.js` HTTPS support | ✅ Fixed | `MSXML2.ServerXMLHTTP.6.0` + configurable scheme |
| `ha-control.js` JSON injection | ✅ Mitigated | `escapeJson()` applied to `entityId` |
| Light state "unavailable" display | ✅ Fixed | "Unavailable" (distinct from "OFF") |
| Media state "unavailable" display | ✅ Fixed | "Unavailable" added to all 4 meters |
| Dead code removal | ✅ Clean | `ha-control.ps1.example` deleted |
| Unused config cleanup | ✅ Clean | 4 unused vars removed from Settings.inc.example |
| `.gitignore` coverage | ✅ Fixed | `.qa-tmp/` added |
| UNIT_TEMP duplication | ✅ Fixed | Ini no longer overrides Settings.inc |
| Unused measure | ✅ Removed | `MeasureSensorPct` deleted |
| Core skin structure | ✅ Intact | No duplicate sections, all MeasureName refs valid |

---

## Additional Observations

1. **Configuration Duplication:** `ha-control.js` maintains its own copy of `HA_SERVER`, `HA_TOKEN`, `HA_SSL`, `HA_PORT` — users must sync with `Settings.inc`. Not a regression (pre-existing), but a maintenance burden.

2. **Example vs Live Files:** All fixes applied to `.example` templates. Live files (`Settings.inc`, `ha-control.js`) are gitignored and must be manually updated by users. This is the intended workflow.

3. **ServerXMLHTTP Choice:** `MSXML2.ServerXMLHTTP.6.0` is correct for HTTPS support in WSH/JScript. The `setTimeouts` signature (resolve, connect, send, receive) is correct for this ProgID.

4. **Line Ending Warning:** Git reports `LF will be replaced by CRLF` for modified files. This is a cosmetic git config issue (`core.autocrlf`), not a functional problem.

---

## Verdict

**Ready to merge for HIGH/MEDIUM fixes.** The critical crash patterns (LIQUIDGLASS-001), operational failures (LIQUIDGLASS-002, 003), and security gap (LIQUIDGLASS-004) are all correctly resolved.

**Recommended follow-up (separate PR):**
1. Complete JSON escaping in `ha-control.js` (LIQUIDGLASS-010)
2. Address `MeterDot` dynamic status (LIQUIDGLASS-014) — requires new availability measure
3. Add weather condition fallback or document limitation (LIQUIDGLASS-013)
4. Audit remaining `isInt=true` on select/todo entities (line 462 is highest risk)

No blocking defects. The fixes are correct, complete for their stated scope, and introduce no regressions.

---

## 11. Post-Implementation Adversarial Review — T1–T9 (2026-10-08)

**Review Date:** 2026-10-08  
**Baseline Commit:** 855ea5c (T1–T9 complete)  
**Scope:** Review of all 9 tasks implemented in `tomorrow.md`

---

### 11.1 New Findings from T1–T9 Implementation

| ID | Severity | Description | File/Line | Blocking? |
|---|---|---|---|---|
| **ADV-001** | HIGH | LightControlMode close button `Hidden` inverted: `Hidden=(#LightControlMode# = 0)` → visible when mode=0, hidden when mode=1/2/3. Should be `<>` | `LiquidGlass.ini:1437` | **YES** |
| **ADV-002** | HIGH | Brightness bar click uses `$MouseX$` directly (skin-relative 0-380) instead of bar-relative (0-120) mapped to 0-255. Bar at X=212/46, width=120px. Formula: `Clamp(Round(($MouseX$ - barX) / 120 * 255), 0, 255)` | `LiquidGlass.ini:1236,1365,1428` | **YES** |
| **ADV-003** | MEDIUM | `ha-control.js` passes `serviceData` unescaped — caller must provide pre-escaped JSON. Current hardcoded swatches OK, but pattern is fragile for dynamic values. | `@Resources/ha-control.js:34-35` | NO |
| **ADV-004** | LOW | Media prev/next triangles: 12px wide polygons with `X=0,Y=0`. Hit area = bounding box, but triangles small. Hard to click accurately. | `LiquidGlass.ini:1462+` | NO |
| **ADV-005** | LOW | Lightstrip color: only 6 preset swatches. No custom picker. Feature gap. | `LiquidGlass.ini:1250+` | NO |
| **ADV-006** | INFO | `TIME_FORMAT` and `UNIT_TEMP` in `LiquidGlass.ini` `[Variables]` but not in `Settings.inc.example` — users can't configure without editing INI. | `LiquidGlass.ini:96-97` | NO |
| **ADV-007** | INFO | `wxcond.js` fallback: unknown codes fall through to raw slug (not "—"). | `@Resources/wxcond.js:22` | NO |

---

### 11.2 Fix Verification for New Code

| Task | Code Area | Verified? | Issues |
|---|---|---|---|
| T1: Humidity layout | `LiquidGlass.ini:1078-1094` | ✅ | Correct position, label added |
| T2: Weather condition | `@Resources/wxcond.js` | ✅ | Maps all standard HA codes; cscript syntax OK |
| T4: Media prev/next | `LiquidGlass.ini:1462-1601` | ⚠️ | Triangles small (ADV-004); services correct |
| T5: Light brightness/color | `LiquidGlass.ini:1126-1440` | ⚠️ | **Logic bug** in brightness click (ADV-002); color swatches work |
| T6: 12/24h time | `@Resources/timeformat.js` | ✅ | cscript syntax OK; logic correct |
| T7: °C/°F temp | `@Resources/tempformat.js` | ✅ | cscript syntax OK; conversion correct |
| T8: Glass panel | `LiquidGlass.ini:915-932` | ✅ | Inner highlight/shadow; noise 40% |
| T9: Performance | `LiquidGlass.ini` (all measures) | ✅ | 48 disabled; UpdateDivider consolidated; 5 new measures |

---

### 11.3 Blocking Defects (Must Fix Before Merge)

1. **ADV-001 (HIGH):** Close button `Hidden` condition inverted — breaks light control UX entirely (close button never visible when needed)
2. **ADV-002 (HIGH):** Brightness bar click sends raw mouse X (e.g., 212-332) as brightness (0-255) — sets brightness to ~83-130% instead of 0-100%. Feature non-functional.

---

### 11.4 Non-Blocking Issues

3. **ADV-003 (MEDIUM):** `serviceData` escape gap — document or fix
4. **ADV-004 (LOW):** Media triangle hit area — consider transparent overlay
5. **ADV-005 (LOW):** Lightstrip color presets only — acceptable for v1
6. **ADV-006 (INFO):** Config vars missing from `Settings.inc.example`
7. **ADV-007 (INFO):** `wxcond.js` unknown code fallback

---

### 11.5 Regression Check (T1–T9 vs Baseline)

| Area | Baseline | T1–T9 | Status |
|------|----------|-------|--------|
| Duplicate sections | 0 | 0 | ✅ |
| Dangling MeasureName | 2 (MeasureWxStateWeb) | 0 | ✅ Fixed |
| `isInt=true` count | 3 | 6 | ✅ Expected (+3 brightness) |
| Unavailable handling | 4 light + 4 media | 4 light + 4 media | ✅ |
| `ha-control.js` syntax | PASS | PASS | ✅ |
| New JS files syntax | N/A | PASS | ✅ (4 files) |
| Git secrets | 1 tracked file | 1 tracked file | ⚠️ Pre-existing |

---

### 11.6 Updated Verdict

**NOT ready to merge** — 2 blocking HIGH defects (ADV-001, ADV-002) introduced in T5 implementation.

**Required fixes before merge:**
1. Fix `Hidden` condition on `[MeterLightCloseBtn]` line 1437: change `=` to `<>`
2. Fix brightness bar click actions — implement bar-relative mouse position mapping to 0-255

**Recommended (same PR):**
3. Apply `escapeJson` to `serviceData` in `ha-control.js` or add validation
4. Add `TIME_FORMAT` and `UNIT_TEMP` to `Settings.inc.example`
5. Consider larger hit area for media triangles

**Can defer:**
6. Lightstrip custom color picker
7. `wxcond.js` unknown code display

---

### 11.7 Suggested Fix for ADV-002 (Brightness Bar)

Option A — Use a Script measure to compute brightness from mouse position:
```ini
[MeasureBrightnessFromClick]
Measure=Script
ScriptFile=#@#brightnessclick.js
Parameter=$MouseX$
```

Option B — Use Calc measure with nested syntax (complex in Rainmeter):
```ini
[MeasureBrightnessCalc]
Measure=Calc
Formula=Clamp(Round(($MouseX$ - 212) / 120 * 255), 0, 255)
DynamicVariables=1
```

Option C — Keep simple: use 4 brightness preset buttons (25%, 50%, 75%, 100%) instead of slider.

---

**Adversarial Reviewer Signature:** _Adversarial Code Review Agent_  
**Date:** 2026-10-08