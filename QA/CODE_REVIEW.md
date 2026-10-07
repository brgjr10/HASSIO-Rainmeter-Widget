# Code Review — HASSIO-Rainmeter-Widget (LiquidGlass)

| Field | Value |
|---|---|
| Review type | Adversarial (fresh agent, no prior context) |
| Reviewer | Adversarial Code Review Agent (subagent) |
| Baseline commit | a6bbcc7 |
| Diff reviewed | Working tree (5 modified, 1 deleted, 1 new untracked) |
| Review date | 2026-10-06 |

---

## Verdict

**READY TO MERGE for HIGH/MEDIUM fixes.** All 4 HIGH and 3 MEDIUM findings from the QA report have been correctly resolved. No blocking regressions introduced. 2 LOW findings remain unfixed (by design — owner decision deferred). 1 LOW finding partially addressed.

---

## BLOCKING Defects

**None.**

---

## NON-BLOCKING Issues

### 1. LIQUIDGLASS-010 Partial — Incomplete JSON escaping
- **File:** `ha-control.js.example:16-23`
- **Issue:** `escapeJson()` handles `\\`, `"`, `\n`, `\r`, `\t` but misses `\b`, `\f`, and unicode `\uXXXX`
- **Impact:** LOW — entity IDs follow `domain.object_id` (alphanumeric + underscore), so exploitation is unlikely. A malformed entity ID with `\b` or `\f` would produce invalid JSON.
- **Recommendation:** Extend `escapeJson` or document the entity ID constraint (accepted as sufficient for this use case).

### 2. LIQUIDGLASS-013 Unfixed — Weather condition lacks catch-all
- **File:** `LiquidGlass.ini:890`
- **Issue:** `Substitute` maps known HA weather states but has no fallback for unknown/custom states
- **Impact:** LOW — cosmetically, unknown states display as raw slug
- **Recommendation:** Document as accepted limitation or add fallback meter in a follow-up PR

### 3. LIQUIDGLASS-014 Unfixed — MeterDot static green
- **File:** `LiquidGlass.ini:819-822`
- **Issue:** `[MeterDot]` has no `MeasureName`, no dynamic color binding
- **Impact:** LOW — indicator shows green even when HA is unreachable
- **Recommendation:** Add HA-availability measure with `DynamicVariables=1` + `IfCondition` in a follow-up PR

### 4. Pre-existing — isInt=true on SELECT entity
- **File:** `LiquidGlass.ini:462`
- **Issue:** `MeasureSelectSmartPlugPowerOnBehavior` uses `isInt=true` on a SELECT entity that returns a string state
- **Impact:** MEDIUM — latent crash risk (String → isInt parse failure), **not a regression**
- **Recommendation:** Remove `isInt=true` from SELECT entities in a follow-up PR

---

## Regression Check

| Area | Status | Evidence |
|------|--------|----------|
| Error handling in ha-control.js | ✅ Improved | try/catch + `xhr.status` check + `WScript.Quit(1)` |
| Timeout | ✅ Fixed | `setTimeouts(10000, 10000, 10000, 10000)` on ServerXMLHTTP |
| HTTPS support | ✅ Fixed | `MSXML2.ServerXMLHTTP.6.0` + configurable `HA_SSL` scheme |
| JSON injection | ✅ Mitigated | `escapeJson()` applied to `entityId` |
| Light unavailable display | ✅ Fixed | `"unavailable":"Unavailable"` (distinct from `"OFF"`) |
| Media unavailable display | ✅ Fixed | `"Unavailable"` added to all 4 media meters |
| Dead code removal | ✅ Clean | `ha-control.ps1.example` deleted |
| Unused config cleanup | ✅ Clean | 4 unused vars removed from `Settings.inc.example` |
| `.gitignore` coverage | ✅ Fixed | `.qa-tmp/` added |
| UNIT_TEMP duplication | ✅ Fixed | Ini override removed; now sourced from Settings.inc (°F) |
| Unused measure | ✅ Removed | `MeasureSensorPct` deleted |
| Core skin structure | ✅ Intact | No duplicate sections, all `MeasureName` refs valid |

---

## Additional Observations (Non-Blocking)

1. **Config duplication** — `ha-control.js` maintains its own copy of `HA_SERVER`, `HA_TOKEN`, `HA_SSL`, `HA_PORT` — users must sync with `Settings.inc`. Pre-existing, not a regression.
2. **Example vs Live files** — All fixes applied to `.example` templates. Live files (`Settings.inc`, `ha-control.js`) are gitignored. This is the intended workflow.
3. **Line endings** — Git reports `LF will be replaced by CRLF` for modified files. Cosmetic `core.autocrlf` config issue, not functional.

---

## Full Review

The full adversarial review is available at `QA/adversarial-review.md`.
