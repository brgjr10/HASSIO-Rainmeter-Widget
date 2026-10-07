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

## New findings from adversarial review

| Source ID | Severity | Description | Status |
|---|---|---|---|
| ADVERSARIAL-001 | MEDIUM | `isInt=true` still present on `MeasureSelectSmartPlugPowerOnBehavior` (line 462) — SELECT entity returns string state | OPEN — not a regression, pre-existing |
| ADVERSARIAL-002 | LOW | `escapeJson()` does not handle `\b`, `\f`, or unicode escapes | OPEN — LOW risk (entity IDs are alphanumeric) |

## Regressions

**None.** All 12 fixes verified correct by the adversarial reviewer. No functionality broken.
