# Findings & Fixes Ledger — HASSIO-Rainmeter-Widget (LiquidGlass)

| Baseline | a6bbcc7 | Review date | 2026-10-06 |
|---|---|---|---|

| Source ID | Severity | Description | Fix status | Fix files | Verified by |
|---|---|---|---|---|---|
| LIQUIDGLASS-001 | HIGH | `isInt=true` crash on 4 float-valued measures (temp, humidity, effect speed, battery) | FIXED | `LiquidGlass.ini` | `validate-skin.ps1:2`, cscript test, adversarial review |
| LIQUIDGLASS-002 | HIGH | ha-control.js example has no error handling — unhandled runtime error | FIXED | `ha-control.js.example` | cscript test (graceful error + exit 1), adversarial review |
| LIQUIDGLASS-003 | MEDIUM | Sync XHR with no timeout — hangs if HA unreachable | FIXED | `ha-control.js.example` | cscript test, adversarial review |
| LIQUIDGLASS-004 | MEDIUM | Hardcoded HTTP — no HTTPS support | FIXED | `ha-control.js.example` | cscript test, adversarial review |
| LIQUIDGLASS-005 | MEDIUM | Light state meters map "unavailable" → "Off" (confusable with "OFF") | FIXED | `LiquidGlass.ini` | `validate-skin.ps1:3`, grep, adversarial review |
| LIQUIDGLASS-006 | LOW | `MeasureSensorPct` defined but never referenced | FIXED | `LiquidGlass.ini` | `validate-skin.ps1:6`, grep, adversarial review |
| LIQUIDGLASS-007 | LOW | `UNIT_TEMP` duplicated with conflicting values (F vs °F) | FIXED | `LiquidGlass.ini` | `validate-skin.ps1:5`, grep, adversarial review |
| LIQUIDGLASS-015 | LOW | No humidity display — `MeasureWxHum` measure exists but no meter | FIXED | `LiquidGlass.ini` | Added `[MeterWxHum]` at line 971, validation pass |
| LIQUIDGLASS-016 | LOW | `validate-skin.ps1` incorrectly flags valid `UNIT_TEMP=F` config | FIXED | `scripts/validate-skin.ps1` | Check 5 now validates exactly one occurrence |
| LIQUIDGLASS-008 | LOW | Media state meters don't handle "unavailable" | FIXED | `LiquidGlass.ini` | `validate-skin.ps1:4`, grep, adversarial review |
| LIQUIDGLASS-009 | LOW | `ha-control.ps1.example` dead code | FIXED (deleted) | `@Resources/ha-control.ps1.example` | `validate-skin.ps1:12`, `Test-Path`, adversarial review |
| LIQUIDGLASS-010 | LOW | entityId concatenated into JSON without escaping | PARTIAL | `ha-control.js.example` | adversarial review (escapeJson missing `\b`, `\f`, unicode) |
| LIQUIDGLASS-011 | LOW | ha-control.ps1.example silently swallows errors | FIXED (deleted) | `@Resources/ha-control.ps1.example` | Same as LIQUIDGLASS-009 |
| LIQUIDGLASS-012 | LOW | `.qa-tmp/` not in `.gitignore` | FIXED | `.gitignore` | `validate-skin.ps1:10`, grep, adversarial review |
| LIQUIDGLASS-013 | LOW | Weather condition Substitute has no catch-all | NOT FIXED | — | Owner decision deferred (Rainmeter Substitute limitation) |
| LIQUIDGLASS-014 | LOW | MeterDot static green — no HA connectivity indication | NOT FIXED | — | Owner decision deferred (needs new availability measure) |
| INFO-001 | INFO | Unused config variables in Settings.inc.example | FIXED | `Settings.inc.example` | `validate-skin.ps1:11`, grep, adversarial review |

## Summary

| Status | Count |
|---|---|
| FIXED (complete) | 13 |
| FIXED (partial) | 1 (LIQUIDGLASS-010) |
| NOT FIXED (deferred) | 2 (LIQUIDGLASS-013, LIQUIDGLASS-014) |
| NOT FIXED (pre-existing, not in scope) | 1 (isInt on SELECT entity, line 462) |
| NEW OPEN (this review) | 6 (LIQUIDGLASS-017 through -022) |
| NEW INFO (this review) | 2 (LIQUIDGLASS-023, -024) |

## New findings from adversarial review

| Source ID | Severity | Description | Status |
|---|---|---|---|
| ADVERSARIAL-001 | MEDIUM | `isInt=true` still present on `MeasureSelectSmartPlugPowerOnBehavior` (line 462) — SELECT entity returns string state | OPEN — not a regression, pre-existing |
| ADVERSARIAL-002 | LOW | `escapeJson()` does not handle `\b`, `\f`, or unicode escapes | OPEN — LOW risk (entity IDs are alphanumeric) |

## Regressions

**None.** All 12 fixes verified correct by the adversarial reviewer. No functionality broken.

---

## New findings from post-T1-T9 review (2026-10-08)

| Source ID | Severity | Description | Status |
|---|---|---|---|
| LIQUIDGLASS-017 | HIGH | LightControlMode close button `Hidden` condition inverted: `Hidden=(#LightControlMode# = 0)` should be `Hidden=(#LightControlMode# <> 0)`. Close button visible when mode=0 (should be hidden), hidden when mode=1/2/3 (should be visible). | OPEN |
| LIQUIDGLASS-018 | HIGH | Brightness bar click actions use `$MouseX$` directly (skin-relative X position 0-380) instead of bar-relative position mapped to 0-255. Bar starts at X=212/46, width=120px. Formula should be `Clamp(Round(($MouseX$ - barX) / 120 * 255), 0, 255)`. Current sends raw X (e.g., 212-332) as brightness. | OPEN |
| LIQUIDGLASS-019 | MEDIUM | `ha-control.js` does not escape `serviceData` (3rd arg) — caller must provide pre-escaped JSON. Risk: injection if dynamic values used. Current hardcoded swatches OK, but pattern is fragile. | OPEN |
| LIQUIDGLASS-020 | LOW | Media prev/next triangle hit areas: `Shape=Polygon` with absolute coords + `X=0,Y=0` — clickable area is shape bounding box but triangles are small (12px wide). May be hard to click accurately. | OPEN |
| LIQUIDGLASS-021 | LOW | Lightstrip color control: only 6 preset swatches, no custom color picker. Feature gap, not a bug. | OPEN |
| LIQUIDGLASS-022 | INFO | Added 5 new Plugin measures (UpdateDivider=5): lightstrip brightness, lightstrip color, living room lamp brightness, bedroom lamp brightness, light control mode. Net +5 HA polls/5s vs prior state. Offset by 48 disabled measures. | INFO |
| LIQUIDGLASS-023 | INFO | `TIME_FORMAT` and `UNIT_TEMP` variables now in `[Variables]` section of LiquidGlass.ini but should also be in `@Resources/Settings.inc.example` for user configuration. | OPEN |
| LIQUIDGLASS-024 | INFO | `wxcond.js` now maps HA condition codes to human-readable text. Covers all standard HA codes. Unknown codes fall through to raw code (not "—"). | INFO |
