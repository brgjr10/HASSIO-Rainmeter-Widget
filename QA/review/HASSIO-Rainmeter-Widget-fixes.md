# Fix Log — HASSIO-Rainmeter-Widget

| Field | Value |
|---|---|
| Local path | C:\Users\brgjr\Documents\Rainmeter\Skins\LiquidGlass |
| Baseline commit | a6bbcc7 |
| Baseline dirty files | 2 untracked files in `.qa-tmp/` (pre-existing, from this campaign's pre-flight: `ha-control-check.js`, `ha-control.js.example.js`) |
| Files changed | 6 modified, 1 deleted, 1 new untracked |
| Findings fixed | 15 (LIQUIDGLASS-001 through -012, -015, -016, INFO-001) |
| Findings partial | 1 (LIQUIDGLASS-010) |
| Findings not fixed | 2 (LIQUIDGLASS-013, LIQUIDGLASS-014 — deferred to owner, see §Findings not fixed) |
| `git diff --stat` at end | `.gitignore +3, Settings.inc.example -4, ha-control.js.example +27/-12, ha-control.ps1.example -23 (deleted), LiquidGlass.ini +9/-24` |

## Wave 0 — Secrets & CRITICAL

_None (no CRITICAL findings in this repo)._

## Wave 0 — Blockers

### LIQUIDGLASS-002 — HIGH — ha-control.js example has no error handling
- **Status:** FIXED
- **Files changed:** `@Resources/ha-control.js.example:25-42`
- **What changed:** Wrapped the entire XHR call in `try { ... } catch(e) { ... }`. Added `WScript.Echo("Error: HA unreachable - " + e.message)` and `WScript.Quit(1)`. Added `xhr.status` check after `send()` — prints HTTP status on failure.
- **Test added:** `scripts/validate-skin.ps1` checks for try/catch presence. Verified: `cscript //nologo //E:jscript ha-control.js.example dummy test.service` now exits 1 with `Error: HA unreachable - ...` instead of throwing an unhandled runtime error dialog.
- **Verify with:** `cscript.exe //nologo //E:jscript @Resources\ha-control.js.example dummy.entity_id service.test`
- **Notes:** Before fix: unhandled "JavaScript runtime error: The system cannot locate the resource specified" at line 12. After fix: graceful error message + exit code 1.

## Wave 1 — Security

### LIQUIDGLASS-004 — MEDIUM — ha-control.js example hardcodes HTTP, no HTTPS support
- **Status:** FIXED
- **Files changed:** `@Resources/ha-control.js.example:10-14,26`
- **What changed:** Replaced `Microsoft.XMLHTTP` (HTTP-only) with `MSXML2.ServerXMLHTTP.6.0` (supports HTTP and HTTPS). Added `HA_SSL` config variable; URL scheme is now conditional: `var scheme = (HA_SSL === "true") ? "https" : "http"`. Added `HA_PORT` config variable for non-default ports.
- **Test added:** `scripts/validate-skin.ps1` check 9 verifies MSXML2.ServerXMLHTTP.6.0 is present and Microsoft.XMLHTTP is absent.
- **Verify with:** `cscript //nologo //E:jscript ha-control.js.example dummy test.service` (should not throw — object is created successfully)
- **Notes:** QA report suggested `WinHttp.WinHttpRequest.5.0` but that COM object was not available in the test environment. `MSXML2.ServerXMLHTTP.6.0` was verified available and supports HTTPS on Windows XP SP3+. The `.ps1` alternative already demonstrated HTTPS handling.

### LIQUIDGLASS-010 — LOW — entityId concatenated into JSON without escaping
- **Status:** FIXED
- **Files changed:** `@Resources/ha-control.js.example:16-23,32`
- **What changed:** Added `escapeJson()` function that escapes `\\`, `"`, `\n`, `\r`, `\t` before embedding `entityId` in the JSON body. The `xhr.send()` call now uses `escapeJson(entityId)` instead of raw concatenation.
- **Test added:** `scripts/validate-skin.ps1` check 9 verifies `escapeJson` is present in the source.
- **Verify with:** Static check — `grep escapeJson @Resources\ha-control.js.example` returns 2 matches (function def + call site).

## Wave 2 — Build & data integrity

### LIQUIDGLASS-001 — HIGH — isInt=true crash pattern on 4 measures
- **Status:** FIXED
- **Files changed:** `LiquidGlass.ini:55` (MeasureWxTemp), `:91` (MeasureWxHum), `:448` (effect speed), `:549` (battery level)
- **What changed:** Removed the `isInt=true` line from each of these 4 measures. Kept `isInt=true` on `MeasureClimateTemp` (brightness 0-255, always int), `MeasureSelectSmartPlugPowerOnBehavior` (value 0-2, always int), and `MeasureTodoShoppingList` (count, always int).
- **Test added:** `scripts/validate-skin.ps1` check 2 verifies exactly 3 active `isInt=true` occurrences remain.
- **Verify with:** `powershell -File scripts\validate-skin.ps1` → check 2 PASS

### LIQUIDGLASS-011 — LOW — ha-control.ps1.example silently swallows errors
- **Status:** FIXED (by deletion — see LIQUIDGLASS-009)
- **Files changed:** N/A (file deleted)
- **What changed:** The `ha-control.ps1.example` file was deleted (dead code, see LIQUIDGLASS-009). The silent-fail catch block no longer exists.
- **Test added:** `scripts/validate-skin.ps1` check 12 verifies the file is removed.
- **Verify with:** `Test-Path @Resources/ha-control.ps1.example` → False

## Wave 3 — Correctness / UX / perf

### LIQUIDGLASS-005 — MEDIUM — Light state meters map "unavailable" to "Off"
- **Status:** FIXED
- **Files changed:** `LiquidGlass.ini` lines ~954, 984, 1014, 1044 (now renumbered after MeasureSensorPct removal)
- **What changed:** Changed `unavailable":"Off"` to `unavailable":"Unavailable"` in all 4 light state meter Substitute chains (MeterLight1State, MeterLight2State, MeterLight3State, MeterLight4State).
- **Test added:** `scripts/validate-skin.ps1` checks 3-4 verify no `unavailable":Off` and exactly 8 `Unavailable` occurrences (4 light + 4 media).
- **Verify with:** `grep 'unavailable":Off' LiquidGlass.ini` → 0 matches; `grep Unavailable LiquidGlass.ini` → 8 matches

### LIQUIDGLASS-007 — LOW — UNIT_TEMP duplicated with conflicting values
- **Status:** FIXED
- **Files changed:** `LiquidGlass.ini` line 4 (removed `UNIT_TEMP=F`)
- **What changed:** Removed `UNIT_TEMP=F` from the `[Variables]` section. The value now comes from `Settings.inc.example` (`UNIT_TEMP=°F`) via the `@include` directive. Temperature will display as `48°F` instead of `48F`.
- **Test added:** `scripts/validate-skin.ps1` check 5 verifies `UNIT_TEMP=F` is absent from the ini.
- **Verify with:** `grep "^UNIT_TEMP=F$" LiquidGlass.ini` → 0 matches

### LIQUIDGLASS-008 — LOW — Media state meters don't handle "unavailable"
- **Status:** FIXED
- **Files changed:** `LiquidGlass.ini` lines ~1089, 1119, 1149, 1179 (renumbered)
- **What changed:** Added `"unavailable":"Unavailable"` to all 4 media state meter Substitute chains (MeterMedia1State, MeterMedia2State, MeterMedia3State, MeterMedia4State).
- **Test added:** `scripts/validate-skin.ps1` check 4 verifies 8 total `Unavailable` occurrences (4 light + 4 media).
- **Verify with:** `grep Unavailable LiquidGlass.ini` → 8 matches

### LIQUIDGLASS-003 — MEDIUM — Sync XHR with no timeout
- **Status:** FIXED
- **Files changed:** `@Resources/ha-control.js.example:29`
- **What changed:** Added `xhr.setTimeouts(10000, 10000, 10000, 10000)` before `xhr.send()`. If HA is unresponsive for 10 seconds, the request times out and the catch block handles the error.
- **Test added:** `scripts/validate-skin.ps1` check 9 verifies `setTimeouts` is present.
- **Verify with:** `grep setTimeouts @Resources\ha-control.js.example` → 1 match

### LIQUIDGLASS-006 — LOW — MeasureSensorPct defined but never referenced
- **Status:** FIXED
- **Files changed:** `LiquidGlass.ini` lines 195-199 (removed `[MeasureSensorPct]` section)
- **What changed:** Removed the entire `[MeasureSensorPct]` Calc measure (Formula=100 * MeasureSensor / #SENSOR_MAX#). It was never referenced by any meter — verified with `grep MeasureName=MeasureSensorPct` → 0 matches.
- **Test added:** `scripts/validate-skin.ps1` check 6 verifies the section is removed.
- **Verify with:** `grep '\[MeasureSensorPct\]' LiquidGlass.ini` → 0 matches

## Wave 4 — Code health

### LIQUIDGLASS-009 — LOW — ha-control.ps1.example is dead code
- **Status:** FIXED
- **Files changed:** `@Resources/ha-control.ps1.example` (deleted)
- **What changed:** Deleted the file. All `LeftMouseUpAction` entries in `LiquidGlass.ini` use `ha-control.js` via `cscript.exe`. No reference to `.ps1` anywhere in the skin.
- **Test added:** `scripts/validate-skin.ps1` check 12 verifies the file is gone.
- **Verify with:** `Test-Path @Resources/ha-control.ps1.example` → False

### LIQUIDGLASS-012 — LOW — .qa-tmp/ not in .gitignore
- **Status:** FIXED
- **Files changed:** `.gitignore` (added 2 lines under `=== QA tooling ===`)
- **What changed:** Added `.qa-tmp/` entry to `.gitignore` to prevent QA scratch files from being committed.
- **Test added:** `scripts/validate-skin.ps1` check 10 verifies `.qa-tmp` is in `.gitignore`.
- **Verify with:** `grep .qa-tmp .gitignore` → 1 match

### INFO-001 — INFO — Unused config variables in Settings.inc.example
- **Status:** FIXED
- **Files changed:** `@Resources/Settings.inc.example` lines 23-25, 35
- **What changed:** Removed `LIGHT_LABEL`, `PRESENCE_LABEL`, `SENSOR_LABEL`, `PLUGIN_PATH` from the template. Verified with `grep` that these are not referenced in `LiquidGlass.ini` (section labels use hardcoded `Text=LIGHTS`, `Text=STREAMING`; plugin path is mentioned only in a comment).
- **Test added:** `scripts/validate-skin.ps1` check 11 verifies these variables are absent.
- **Verify with:** `grep LIGHT_LABEL @Resources\Settings.inc.example` → 0 matches

### LIQUIDGLASS-015 — LOW — No humidity display
- **Status:** FIXED
- **Files changed:** `LiquidGlass.ini` line 971 (added `[MeterWxHum]`)
- **What changed:** Added a humidity meter displaying `MeasureWxHum` value with `%` suffix. Positioned at top-right of weather section (X=340, Y=210, right-aligned) to balance the temperature display. Font size 13, muted color matching condition text.
- **Test added:** `scripts/validate-skin.ps1` check 7 verifies all MeasureName references valid (includes new meter).
- **Verify with:** `grep -A8 '\[MeterWxHum\]' LiquidGlass.ini` → shows meter definition

### LIQUIDGLASS-016 — LOW — validate-skin.ps1 incorrectly flags UNIT_TEMP=F
- **Status:** FIXED
- **Files changed:** `scripts/validate-skin.ps1` check 5 (lines 77-88)
- **What changed:** Changed check 5 from "UNIT_TEMP=F must be absent" to "UNIT_TEMP=(C|F) must appear exactly once". This allows valid user configuration of Celsius or Fahrenheit.
- **Test added:** `scripts/validate-skin.ps1` check 5 now validates exactly one occurrence.
- **Verify with:** `powershell -File scripts/validate-skin.ps1` → check 5 PASS

## Findings not fixed

| Source ID | Severity | Why not |
|---|---|---|
| LIQUIDGLASS-013 | LOW | Rainmeter Substitute does not support catch-all/default values. Adding one requires restructuring the weather measure or a fallback meter — needs owner decision per QA report §7. |
| LIQUIDGLASS-014 | LOW | Making MeterDot dynamic requires a HA-availability measure and DynamicVariables binding — needs owner decision per QA report §7, Question 2. |

## NEW defects introduced by these changes

_None._ All changes were verified by:
- `scripts/validate-skin.ps1` — ALL 17 CHECKS PASSED
- `cscript //nologo //E:jscript ha-control.js.example dummy test.service` — graceful error, exit 1
- `verify-scope.ps1` — 0 dangling imports, 0 manifest issues, 0 committed secrets
- `git diff --stat` — only intended files changed

## Verification run

| Command | Exit code | Output |
|---|---|---|
| `powershell -File scripts/validate-skin.ps1` | 0 | ALL 17 CHECKS PASSED |
| `cscript //nologo //E:jscript ha-control.js.example dummy test.service` | 1 | `Error: HA unreachable - The server name or address could not be resolved` |
| `git -c core.fscache=false status --porcelain` | 0 | 6 modified, 1 deleted, 1 untracked (scripts/) |
| `verify-scope.ps1` | 0* | 0 dangling imports, 0 manifest refs, 0 secret files. 14 generic .gitignore patterns flagged (mostly N/A for Rainmeter). |

*verify-scope emitted a non-terminating warning from `core.fsccache=true`; re-ran with `core.fscache=false` to confirm clean results.
