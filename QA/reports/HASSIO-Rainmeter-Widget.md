# QA Report — HASSIO-Rainmeter-Widget

| Field | Value |
|---|---|
| GitHub | https://github.com/brgjr10/HASSIO-Rainmeter-Widget |
| Local path | C:\Users\brgjr\Documents\Rainmeter\Skins\LiquidGlass |
| Commit | a6bbcc7 |
| Branch | main |
| Baseline dirty files | 2 untracked files in `.qa-tmp/` (leftover scratch files from this campaign; `.qa-tmp/` is NOT in `.gitignore`) |
| Findings | 0 critical / 2 high / 3 medium / 9 low / 7 info |

## 1. Architecture summary

LiquidGlass is a Rainmeter desktop skin (INI-based) that connects to a local Home Assistant
instance via the third-party `HomeAssitantPlugin.dll`. The skin (`LiquidGlass.ini`, 1215 lines)
defines 44 plugin measures that poll HA REST API states and ~30 meters that render a 380x980
frosted-glass panel with clock, weather, 4 light tiles, 4 media-player tiles, and a footer.

Device control (light toggle / media play-pause) is handled by `@Resources/ha-control.js`,
launched via `cscript.exe //NoLogo` from `LeftMouseUpAction` on each tile. The script makes a
synchronous `Microsoft.XMLHTTP` POST to the HA services endpoint with a Bearer token.

Configuration (HA server IP, token, entity IDs, labels, units) lives in `@Resources/Settings.inc`
which is **gitignored**. Tracked `.example` files contain placeholders. `BANK.md` documents the
debugging history and known issues; `STRUCTURE.md` documents the file/section map (out of date).

No build system, no package.json, no Dockerfile, no CI, no test framework.

## 2. How this was tested

| Command | Result |
|---|---|
| `git ls-files` | 10 tracked files (see repo table above) |
| `git status --porcelain` | `.qa-tmp/` untracked (2 files) |
| `git log --oneline -5` | 1 commit: `a6bbcc7 Initial commit: Liquid Glass Home Assistant Rainmeter widget` |
| `git -C <repo> branch` | `* main` |
| `git fsck --full` | clean — no corruption |
| `cscript.exe //nologo //E:jscript ha-control.js.example test_entity_id light.toggle` | ERROR: JavaScript runtime error at line 12 — "The system cannot locate the resource specified" (HA unreachable) |
| `[regex]::Matches(LiquidGlass.ini, '^\[(Measure\|Meter)\w+\]')` grouped | No duplicate section names |
| grep `MeasureName=` (12 matches) | All reference defined measures — 0 dangling references |
| `certutil -hashfile noise.png SHA256` | `802efa04...` — first bytes `89 50 4e 47 0d 0a 1a 0a` (PNG magic) — not an LFS pointer |
| `fc /L ha-control.js ha-control.js.example` | Structurally identical (only server IP + token differ) |
| `grep isInt=true` in LiquidGlass.ini | 7 active occurrences (2 commented-out forecast measures excluded) |

**Environment constraints:** No Rainmeter runtime available — `LiquidGlass.ini` analysis is
static only. `cscript.exe` is available for JScript execution but cannot reach HA (192.168.4.110
is not accessible from this environment). Git path is local (`C:\`), not SMB/UNC — the
`tsc`/`pytest` false-pass trap does not apply (no such tools in this project). `git status`
emits a cosmetic warning (`could not open directory 'LiquidGlass.ini /'`) caused by
`core.fscapch=true`; `git fsck` is clean.

## 3. Category coverage

| Category | Result | Notes |
|---|---|---|
| A. Build & deps | INFO | No build system; static INI + JScript analysis only |
| B. Correctness | PARTIAL | 4 isInt=true crash pattern findings; 1 dead-code measure; 1 dead-code helper |
| C. Input validation & injection | PARTIAL | entityId concatenated into JSON without escaping (LOW); HTTP-only (MEDIUM) |
| D. Security & secrets | PARTIAL | Good gitignore coverage; HTTPS gap in JScript helper; token in plaintext file |
| E. Frontend / UI | PARTIAL | unavailable→Off mapping; UNIT_TEMP duplication; unused MeterDot status; dead MeterSensorPct |
| F. Persistence | PASS | Gitignore covers all live config; .example files have placeholders |
| G. Performance | PARTIAL | Sync XHR with no timeout; 7 isInt measures; unused measure |
| H. Operational | PARTIAL | No error handling in ha-control.js; silent fail in ha-control.ps1; no tests |
| I. Cross-cutting | INFO | Single project, no subprojects or monorepo structure |

## 4. Findings

### LIQUIDGLASS-001 — HIGH — `isInt=true` crash pattern on 4 measures that can receive non-integer values

- **File:** `LiquidGlass.ini:55` (MeasureWxTemp), `:91` (MeasureWxHum), `:549` (MeasureSensorIpadBatteryLevel), `:448` (MeasureNumberLivingRoomBrodleSLightstripEffectSpeed)
- **Category:** B (Correctness)
- **Observed:** `BANK.md:23-25` documents this exact crash: `isInt=true` forced numeric parse on non-numeric strings → "Input string was not in a correct format" → measure crash. The fix (remove `isInt=true`) was applied to kiosk brightness/volume but **not** to these 4 measures. `BANK.md:55` also notes: `MeasureNumberLivingRoomBrodleSLightstripEffectSpeed` "occasionally logs `One or more errors occurred`" — still present, still unfixed.
- **Expected:** `isInt=true` should only be on measures whose source values are guaranteed integers.
- **Root cause:** `isInt=true` was added as a blanket pattern for numeric sensors. Temperature, humidity, and battery level can be floats (e.g., 48.5°F, 85.5% humidity, 52.5% battery). Effect speed may return non-numeric states.
- **Impact:** Skin measures crash silently when HA returns a float or non-numeric value. The affected meters (`MeterWxTemp`, `MeterWxHum`, `MeterSensorIpadBatteryLevel`, `MeterNumberLivingRoomBroddieSLightstripEffectSpeed`) display stale or empty data. The effect-speed measure is documented as already flaky.
- **Reproduction:** 1) HA returns float temperature (e.g., 48.5) 2) Rainmeter loads the skin 3) `MeasureWxTemp` crashes with "Input string was not in a correct format" 4) `MeterWxTemp` shows blank or last valid value.
- **Suggested fix:** Remove `isInt=true` from all 4 measures (lines 55, 91, 448, 549). Match the pattern already applied to kiosk brightness/volume in `BANK.md`.
- **Effort:** S (10 minutes)
- **Confidence:** Strong (documented crash pattern, code shows inconsistency)

### LIQUIDGLASS-002 — HIGH — `ha-control.js` has no error handling — unhandled runtime error when HA unreachable

- **File:** `@Resources/ha-control.js.example:8-12` (live `ha-control.js` is structurally identical)
- **Category:** H (Operational)
- **Observed:** Running `cscript.exe //nologo //E:jscript ha-control.js.example test_entity_id light.toggle` produced: `JavaScript runtime error: The system cannot locate the resource specified` at line 12 (`xhr.send(...)`). No try/catch, no status-code check, no user-facing error message. WSH error dialog pops up.
- **Expected:** Network errors should be caught and reported gracefully (e.g., `WScript.Echo("Error: HA unreachable")`), or silently handled so the user isn't interrupted.
- **Root cause:** The JScript makes a synchronous `Microsoft.XMLHTTP` call with zero error handling. Any network failure, DNS resolution failure, or non-200 response throws an unhandled exception.
- **Impact:** Every time HA is briefly unreachable (network glitch, server restart, user on wrong WiFi) and the user clicks a light or media tile, a Windows Script Host error dialog appears. The device does not toggle. This directly contradicts the house standard: "Never silently fail" — the failure here is LOUD but uninformative and interrupts the UI.
- **Reproduction:** 1) Click any light/media tile when HA is unreachable 2) `cscript.exe` launches `ha-control.js` 3) `xhr.send()` throws 4) WSH error dialog appears.
- **Suggested fix:** Wrap the XHR call in `try { ... } catch(e) { WScript.Quit(1); }` and check `xhr.status` before assuming success.
- **Effort:** S (<1h)
- **Confidence:** Confirmed (executed and reproduced)

### LIQUIDGLASS-003 — MEDIUM — `ha-control.js` uses synchronous XMLHttpRequest with no timeout

- **File:** `@Resources/ha-control.js.example:9`
- **Category:** G (Performance & resources)
- **Observed:** `xhr.open("POST", url, false)` — the `false` parameter makes the request synchronous. No `xhr.timeout` is set. If HA accepts the TCP connection but never responds (or responds slowly), `cscript.exe` hangs indefinitely. Since Rainmeter launched the process via `LeftMouseUpAction`, the user sees no feedback and can accumulate multiple hung `cscript.exe` processes.
- **Expected:** Either set a timeout (`xhr.timeout = 10000`) or use async with a callback.
- **Root cause:** Synchronous XHR chosen for simplicity in a simple JScript helper; no timeout configured.
- **Impact:** Unresponsive HA server causes infinite hang. User clicks are swallowed with no feedback.
- **Reproduction:** 1) Start HA but make the services endpoint hang 2) Click a tile 3) `cscript.exe` hangs forever.
- **Suggested fix:** Add `xhr.timeout = 10000;` before `xhr.send()`. Optionally add `xhr.onreadystatechange` for async behavior.
- **Effort:** S (<1h)
- **Confidence:** Strong (read from code; synchronous XHR behavior is well-defined)

### LIQUIDGLASS-004 — MEDIUM — `ha-control.js` hardcodes HTTP — no HTTPS support

- **File:** `@Resources/ha-control.js.example:9` (live `ha-control.js:9` confirmed identical structure: `http://192.168.4.110:8123/...`)
- **Category:** D (Security & secrets)
- **Observed:** The script uses `new ActiveXObject("Microsoft.XMLHTTP")` and `http://...` hardcoded. `Microsoft.XMLHTTP` **does not support HTTPS** — only HTTP. The PowerShell alternative (`ha-control.ps1.example:11`) correctly handles HTTPS via `$Ssl`/`$protocol` logic. The README (line 45) says JScript was chosen specifically to avoid PowerShell execution-policy issues, trading that for HTTPS incompatibility.
- **Expected:** Device control should work whether HA serves HTTP or HTTPS.
- **Root cause:** `Microsoft.XMLHTTP` ActiveXObject only supports HTTP. For HTTPS, `WinHttp.WinHttpRequest.5.0` is required. No SSL handling exists in the JScript.
- **Impact:** All device control (light toggle, media play/pause) is broken if HA uses HTTPS — which is common for self-hosted setups (Let's Encrypt, self-signed certs, remote access). The live config at `192.168.4.110:8123` uses HTTP, so the current setup works locally but would break if the user switches to HTTPS.
- **Reproduction:** 1) Configure HA with HTTPS 2) Click any tile 3) `Microsoft.XMLHTTP` cannot connect to `https://...` — request fails.
- **Suggested fix:** Replace `Microsoft.XMLHTTP` with `WinHttp.WinHttpRequest.5.0` (supports HTTPS via `Option(2)` for secure protocols) and make the URL scheme configurable via a `#SSL#` variable from `Settings.inc`.
- **Effort:** M (half day — involves testing with cscript + WinHttp)
- **Confidence:** Strong (well-documented ActiveXObject limitation; .ps1 alternative already demonstrates the HTTPS path)

### LIQUIDGLASS-005 — MEDIUM — Light state meters map "unavailable" → "Off"

- **File:** `LiquidGlass.ini:954` (MeterLight1State), `:984` (MeterLight2State), `:1014` (MeterLight3State), `:1044` (MeterLight4State)
- **Category:** E (Frontend / UI)
- **Observed:** Each light state meter has `Substitute="on":"ON","off":"OFF","unavailable":"Off"`. When a light is unavailable (HA disconnected, device offline), the meter displays "Off" (capital O, lowercase ff). This is indistinguishable from an actually-off light (which shows "OFF" in all caps).
- **Expected:** "unavailable" should display as "Unavailable" or "—" (a distinct state, not confused with "off").
- **Root cause:** Copy-paste Substitute chain that conflates "unavailable" with "off".
- **Impact:** User believes a disconnected light is simply off. Toggling "Off" → expects it to turn on, but the device is unreachable. Confusing and misleading.
- **Reproduction:** 1) HA goes offline 2) Light tile shows "Off" instead of "Unavailable" 3) User clicks, expecting toggle, but nothing happens.
- **Suggested fix:** Change Substitute to `"unavailable":"Unavailable"` or `"off":"OFF"` with separate unavailable handling. Match the pattern already in meter state Substitutes (which omit unavailable entirely).
- **Effort:** S (<30 min)
- **Confidence:** Confirmed (code shows the mapping clearly)

### LIQUIDGLASS-006 — LOW — `MeasureSensorPct` defined but never referenced

- **File:** `LiquidGlass.ini:196-199`
- **Category:** B (Correctness)
- **Observed:** `[MeasureSensorPct]` is a Calc measure (`Formula=100 * MeasureSensor / #SENSOR_MAX#`) that is never referenced by any meter (no `MeasureName=MeasureSensorPct` anywhere in the file). It consumes a plugin read cycle on every update.
- **Expected:** Either wire it to a meter or remove it.
- **Root cause:** Likely a planned sensor bar visualization that was never implemented.
- **Impact:** Wasted computation; potential source of confusion during maintenance.
- **Suggested fix:** Remove the unused measure, or add a meter that uses it (e.g., a sensor bar).
- **Effort:** S (<15 min)
- **Confidence:** Confirmed (grep `MeasureName=MeasureSensorPct` returns 0 matches)

### LIQUIDGLASS-007 — LOW — `UNIT_TEMP` duplicated with conflicting values in `LiquidGlass.ini` and `Settings.inc.example`

- **File:** `LiquidGlass.ini:4` (`UNIT_TEMP=F`) vs `@Resources/Settings.inc.example:28` (`UNIT_TEMP=°F`)
- **Category:** E (Frontend / UI) / F (Persistence)
- **Observed:** The ini's `[Variables]` section defines `UNIT_TEMP=F` (line 4). The `Settings.inc.example` defines `UNIT_TEMP=°F` (line 28). Because `@include=#@#Settings.inc` is at line 1 (before `[Variables]` at line 3), the `[Variables]` section **overrides** the include's value. The degree symbol (°) is lost.
- **Expected:** Temperature should display as `48°F`, not `48F`.
- **Root cause:** The variable is defined in both the ini's [Variables] section and the included Settings.inc with different values. The [Variables] section's `F` wins.
- **Impact:** Temperature displays as `48F` instead of `48°F`. Minor cosmetic issue.
- **Suggested fix:** Remove `UNIT_TEMP=F` from the ini's `[Variables]` section (line 4) and let the value come from `Settings.inc.example`. Same pattern should be checked for `UNIT_WIND`, `UNIT_PRESS`, `UNIT_SENSOR`, `SENSOR_MAX` — these match between both files, so no issue.
- **Effort:** S (<15 min)
- **Confidence:** Strong (variable resolution order is deterministic in Rainmeter)

### LIQUIDGLASS-008 — LOW — Media state meters do not handle "unavailable" state

- **File:** `LiquidGlass.ini:1089` (MeterMedia1State), `:1119` (MeterMedia2State), `:1149` (MeterMedia3State), `:1179` (MeterMedia4State)
- **Category:** E (Frontend / UI)
- **Observed:** Media state Substitute chains are `"playing":"Playing","paused":"Paused","idle":"Idle","off":"Off"` — "unavailable" is NOT handled. When a media player is disconnected, the raw state string `unavailable` is displayed to the user.
- **Expected:** "unavailable" should be mapped to "Unavailable" or "—".
- **Root cause:** Omission from the Substitute chain (unlike the light meters which DO map it, albeit incorrectly).
- **Impact:** Ugly raw `unavailable` text displayed on media tiles when HA or the device is offline.
- **Suggested fix:** Add `"unavailable":"Unavailable"` to each media state Substitute.
- **Effort:** S (<15 min)
- **Confidence:** Confirmed (code shows the Substitute chains)

### LIQUIDGLASS-009 — LOW — `ha-control.ps1.example` is dead code, not referenced in the skin

- **File:** `@Resources/ha-control.ps1.example` (not referenced in `LiquidGlass.ini`)
- **Category:** B (Correctness) / I (Cross-cutting)
- **Observed:** All `LeftMouseUpAction` entries in `LiquidGlass.ini` (lines 938, 949, 962, 968, 979, 992, 998, 1009, 1028, 1039, 1063, 1073, 1084, 1097, 1103, 1114, 1127, 1133, 1144, 1157, 1163, 1174, 1187) use `ha-control.js` via `cscript.exe`. None reference `ha-control.ps1`. BANK.md (line 51) says: "Uses `cscript.exe //NoLogo` to avoid execution-policy issues that broke the previous PowerShell implementation."
- **Expected:** Either remove the dead `.ps1.example` or wire it in as an alternative.
- **Root cause:** `ha-control.ps1` was the original device-control mechanism, replaced by `ha-control.js`. The `.example` template was left behind.
- **Impact:** Maintenance burden — the `.ps1` could diverge from the `.js` without anyone noticing. It also has a silent-fail (`catch {}`) that wouldn't apply to the active code path.
- **Suggested fix:** Remove `@Resources/ha-control.ps1.example` (it is tracked and never used). If PowerShell is still desired as a documented alternative, add it to README.
- **Effort:** S (<15 min)
- **Confidence:** Confirmed (grep for `ps1` in LiquidGlass.ini returns 0 matches)

### LIQUIDGLASS-010 — LOW — `entityId` concatenated into JSON body without escaping

- **File:** `@Resources/ha-control.js.example:12`
- **Category:** C (Input validation & injection)
- **Observed:** `xhr.send("{\"entity_id\":\"" + entityId + "\"}")` — the `entityId` command-line argument is concatenated directly into the JSON body without escaping. If the argument contains `"`, `}`, `\`, or other JSON-special characters, the body becomes malformed or injects additional JSON fields.
- **Expected:** JSON should be constructed safely (e.g., `JSON.stringify({entity_id: entityId})` or manual escaping).
- **Root cause:** Manual string concatenation instead of JSON serialization.
- **Impact:** Low in practice — entity IDs come from the skin author's `Settings.inc` and follow the `domain.object_id` pattern. But if a user configures a malformed ID, the request silently fails or sends unexpected data.
- **Suggested fix:** Use `JSON.stringify` (not available in WSH JScript) or manual escaping of `entityId` before insertion.
- **Effort:** S (<1h — requires testing in cscript WSH environment)
- **Confidence:** Strong (code is clear; WSH JScript lacks `JSON.stringify`)

### LIQUIDGLASS-011 — LOW — `ha-control.ps1.example` silently swallows all errors

- **File:** `@Resources/ha-control.ps1.example:22`
- **Category:** H (Operational)
- **Observed:** The catch block is `catch { # Silent fail }` — all errors (network failures, auth failures, non-200 responses) are swallowed with no logging, no output, no exit code.
- **Expected:** Errors should be logged with context (what failed, why, possible fix) per house standard.
- **Root cause:** Placeholder error handling left from development.
- **Impact:** If someone uses this script, failures are invisible. Since it's dead code (see LIQUIDGLASS-009), the impact is deferred.
- **Suggested fix:** Add `Write-Error $_.Exception.Message` or `Write-Warning` in the catch block.
- **Effort:** S (<15 min)
- **Confidence:** Confirmed (code shows the empty catch block)

### LIQUIDGLASS-012 — LOW — `.qa-tmp/` is untracked and not in `.gitignore`

- **File:** repo root `.gitignore` (no `.qa-tmp/` pattern)
- **Category:** D (Security & secrets) / F (Persistence)
- **Observed:** The `.gitignore` file (22 lines) covers `.kilo/`, `states.md`, secret config files, and OS junk — but does NOT cover `.qa-tmp/`. The repo root currently has an untracked `.qa-tmp/` directory with 2 files from this campaign. A careless `git add -A` would commit QA scratch files.
- **Expected:** `.qa-tmp/` should be in `.gitignore` (the `verify-scope.ps1` script at `repo-qa\scripts\verify-scope.ps1:32` lists `.qa-tmp` in `$IgnoredDirs` — so the QA tooling expects it to be scratch space).
- **Root cause:** The QA convention (`.qa-tmp/`) was not added to `.gitignore` when the campaign started.
- **Impact:** Risk of accidentally committing QA scratch files (which could contain mock data or test artifacts).
- **Suggested fix:** Add `.qa-tmp/` to `.gitignore`.
- **Effort:** S (<5 min)
- **Confidence:** Confirmed (git status shows `.qa-tmp/` untracked; .gitignore has no such entry)

### LIQUIDGLASS-013 — LOW — `MeterWxCond` weather condition Substitute has no catch-all for unknown states

- **File:** `LiquidGlass.ini:900`
- **Category:** E (Frontend / UI) / B (Correctness)
- **Observed:** The Substitute maps known HA weather states to display text (sunny→Sunny, clear→Clear, etc.) but has no default/catch-all. If HA returns a state not in the list (e.g., a new condition added by a custom component), the raw state string is displayed.
- **Expected:** Unknown states should fall back to a sensible default (e.g., the raw entity state or "Unknown").
- **Root cause:** Omission of a fallback in the Substitute chain.
- **Impact:** A new or custom weather condition would display as a raw slug (e.g., `sunny` without the capitalization). Minor UX issue.
- **Suggested fix:** Can't add a catch-all in Rainmeter Substitute directly — would need to handle in the measure or add a default meter text. Document as accepted limitation or add a fallback meter.
- **Effort:** M (requires understanding Rainmeter Substitute fallback behavior)
- **Confidence:** Strong (code shows the complete Substitute with no default)

### LIQUIDGLASS-014 — LOW — `MeterDot` HA status indicator is always green — does not reflect actual HA connection

- **File:** `LiquidGlass.ini:831-832`
- **Category:** E (Frontend / UI)
- **Observed:** `[MeterDot]` defines a green ellipse (`Fill Color 63,185,80`) as the HA connection status indicator. It is a static Shape meter — no `MeasureName` or dynamic color binding. The dot is always green regardless of whether HA is actually reachable.
- **Expected:** The dot should turn red (or grey) when HA is unreachable.
- **Root cause:** The dot was implemented as a static shape without binding to a connection-status measure. No HA-availability measure exists in the skin.
- **Impact:** User has no visual indication that HA is disconnected — they see a green dot while all entity measures show "unavailable".
- **Suggested fix:** Add a boolean measure that pings HA availability (or checks a core measure's status) and use `DynamicVariables=1` + conditional `Fill Color` on `MeterDot`.
- **Effort:** M (half day — requires a working HA-availability measure)
- **Confidence:** Strong (code shows no MeasureName on MeterDot; no availability measure exists)

### LIQUIDGLASS-INFO-001 — INFO — Unused variables in `Settings.inc.example`

- **File:** `@Resources/Settings.inc.example:23` (`LIGHT_LABEL`), `:24` (`PRESENCE_LABEL`), `:25` (`SENSOR_LABEL`), `:35` (`PLUGIN_PATH`)
- **Category:** B (Correctness)
- **Observed:** `LIGHT_LABEL`, `PRESENCE_LABEL`, `SENSOR_LABEL`, and `PLUGIN_PATH` are defined in `Settings.inc.example` but never referenced in `LiquidGlass.ini` (the section labels use hardcoded `Text=LIGHTS`, `Text=STREAMING`, etc.).
- **Expected:** Either use these variables or remove them to avoid confusion.
- **Impact:** Config bloat — users edit labels that have no effect.
- **Suggested fix:** Remove unused variables from `.example`, or wire them into the meters.
- **Effort:** S (<15 min)
- **Confidence:** Confirmed (grep for `LIGHT_LABEL` in LiquidGlass.ini returns 0 matches)

### LIQUIDGLASS-INFO-002 — INFO — No automated test coverage

- **File:** repo root (no test files or framework)
- **Category:** H (Operational)
- **Observed:** No test directory, no test runner, no CI. BANK.md (line 5) documents manual debugging history.
- **Expected:** At least syntax validation for `ha-control.js` (e.g., `node --check` or cscript parse).
- **Impact:** Bugs are found through manual debugging only (per BANK.md). No regression protection.
- **Suggested fix:** Add a `.qa-tmp/` test script that validates JS syntax via `cscript //nologo //E:jscript` and checks INI structure. Document the command in README.
- **Effort:** S (<1h)
- **Confidence:** Confirmed (no test files in repo)

### LIQUIDGLASS-INFO-003 — INFO — Clean clone: no build system to verify

- **File:** repo root
- **Category:** A (Build & deps)
- **Observed:** No `package.json`, `requirements.txt`, `Dockerfile`, or CI. The "build" is Rainmeter loading the INI — requires the Rainmeter desktop application (Windows-only, not available in this environment).
- **Expected:** N/A — Rainmeter skins are not compiled.
- **Impact:** The skin can only be validated by loading it in Rainmeter 4.5+ on Windows.
- **Suggested fix:** None needed — this is inherent to the project type. Document the requirement in README (already done, line 7).
- **Effort:** N/A
- **Confidence:** Confirmed

### LIQUIDGLASS-INFO-004 — INFO — `.gitignore` properly excludes secret files; `.example` files contain only placeholders

- **File:** `.gitignore:5-7` (excludes `Settings.inc`, `ha-control.js`, `ha-control.ps1`), `states.md:19`
- **Category:** D (Security & secrets)
- **Observed:** `.gitignore` covers all files containing live HA tokens and server config. `git grep` for `Bearer|token|password|secret` in tracked files returns 0 matches (only in `.example` files with `YOUR_HA_TOKEN_HERE` placeholder).
- **Expected:** Secrets should not be in tracked files.
- **Impact:** None — this is a PASS.
- **Confidence:** Confirmed (git grep + .gitignore review)

### LIQUIDGLASS-INFO-005 — INFO — `noise.png` is a real PNG file, not a git-lfs pointer

- **File:** `@Resources/noise.png`
- **Category:** A (Build & deps)
- **Observed:** File is 141,875 bytes. First bytes are `89 50 4e 47 0d 0a 1a 0a` (PNG magic number). SHA256: `802efa04...`. Git config has LFS filter configured, but this file is the actual binary, not an LFS pointer.
- **Expected:** N/A — correct behavior.
- **Impact:** None — file is properly tracked as binary.
- **Confidence:** Confirmed (SHA256 + magic bytes)

### LIQUIDGLASS-INFO-006 — INFO — Git repository is healthy

- **File:** repo root
- **Category:** A (Build & deps)
- **Observed:** `git fsck --full` returns clean. Single commit (`a6bbcc7`) on `main`. No dangling objects. Git config has `core.fsccache=true` which causes a cosmetic status warning but no data issues.
- **Expected:** N/A — healthy state.
- **Confidence:** Confirmed

### LIQUIDGLASS-INFO-007 — INFO — No duplicate section names; all 12 `MeasureName=` references valid

- **File:** `LiquidGlass.ini`
- **Category:** B (Correctness)
- **Observed:** Regex scan found no duplicate `[Measure...]` or `[Meter...]` section names. All 12 `MeasureName=` references point to defined measures.
- **Expected:** No dangling measure references.
- **Impact:** None — this is a PASS.
- **Confidence:** Confirmed (static analysis)

## 5. Test coverage gaps

- **Rainmeter runtime**: Cannot load/verify the skin visually. The skin's visual layout, meter positioning, and runtime behavior in Rainmeter 4.5+ cannot be tested in this environment.
- **HA API integration**: Cannot verify HA plugin measures work correctly — the HomeAssitantPlugin.dll is not present and HA (192.168.4.110) is not reachable.
- **Live ha-control.js/ha-control.ps1**: Cannot test actual device control — these files are gitignored and contain real secrets. Can only validate the `.example` templates.
- **Live Settings.inc**: Cannot verify variable resolution — the live file is gitignored.
- **Git warning**: `git status` emits a cosmetic warning (`could not open directory 'LiquidGlass.ini /'`) caused by `core.fsccache=true`. No impact on findings.

## 6. Pre-existing dirty files

- `.qa-tmp/ha-control-check.js` (429 bytes — copy of `ha-control.js.example`, created during this campaign's pre-flight)
- `.qa-tmp/ha-control.js.example.js` (429 bytes — copy of `ha-control.js.example`, created during this campaign's pre-flight)

Both files in `.qa-tmp/` are created by this campaign (identical to the example file). No pre-existing tracked dirty files — `git status --porcelain --untracked-files=no` returns clean. The `.qa-tmp/` directory is untracked and not in `.gitignore` (see LIQUIDGLASS-012).
