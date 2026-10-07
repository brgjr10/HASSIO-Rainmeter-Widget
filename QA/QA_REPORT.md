# QA Consolidated Report — bug-qa-20261006

## 1. Campaign Summary

### 1.1 Totals by Severity (reconciled)

| Severity | Count |
|---|---|
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 3 |
| LOW | 9 |
| INFO | 7 |
| **Total** | **21** |

### 1.2 Per-Repo Health Table

| Repo | Commit | Build | Tests | Crit | High | Med | Low | Info | Health |
|---|---|---|---|---|---|---|---|---|---|
| HASSIO-Rainmeter-Widget | a6bbcc7 | N/A (no build system) | 0 | 0 | 2 | 3 | 9 | 7 | ⚠️ Needs fixes |

> **Note on counts:** Phase 1 report self-reported 0/2/3/9/7. Reconciliation confirms
> these counts match exactly (21 findings across A–I categories). No finding was silently
> dropped.

### 1.3 Cross-Repo Systemic Pattern Count

Single-repo campaign — no cross-repo patterns. All 21 findings originate in this repo.

## 2. Executive Summary (for the owner)

LiquidGlass is a Rainmeter skin that connects to Home Assistant. The skin itself (INI file)
is structurally sound — no duplicate sections, no dangling measure references, all 10 tracked
files are clean of secrets. However, the device-control helper (`ha-control.js`) has no error
handling and no timeout, meaning any HA unavailability produces a Windows Script Host error
dialog or an infinite hang. Four `isInt=true` measures can crash when HA returns float values
(e.g., 48.5°F), a pattern already documented and fixed for some measures in `BANK.md` but left
unapplied to 4 others. The JScript helper also hardcodes HTTP — HTTPS support is broken.
Light and media tiles display misleading "Off" / raw "unavailable" text when devices
disconnect. No automated tests exist. Recommended: fix the 2 HIGH findings first, then the 3
MEDIUM.

## 3. Consolidated Findings

### 3.1 CRITICAL

_None._

### 3.2 HIGH

#### QA-001 — `isInt=true` crash pattern on 4 measures that can receive non-integer values
- **Source IDs:** LIQUIDGLASS-001
- **File:** `LiquidGlass.ini:55, 91, 448, 549`
- **Observed:** `BANK.md:23-25` documents that `isInt=true` causes "Input string was not in
  a correct format" crashes on non-numeric/float values. The fix (remove `isInt=true`) was
  applied to kiosk brightness/volume but NOT to `MeasureWxTemp`, `MeasureWxHum`,
  `MeasureSensorIpadBatteryLevel`, or `MeasureNumberLivingRoomBroddieSLightstripEffectSpeed`.
  `BANK.md:55` notes the effect-speed measure "occasionally logs `One or more errors occurred`."
- **Impact:** Measures crash silently; meters show stale/blank data.
- **Wave:** 2 (data integrity)
- **Effort:** S
- **Confidence:** Strong

#### QA-002 — `ha-control.js` has no error handling — unhandled runtime error when HA unreachable
- **Source IDs:** LIQUIDGLASS-002
- **File:** `@Resources/ha-control.js.example:8-12`
- **Observed:** `cscript //nologo //E:jscript ha-control.js.example test_entity_id light.toggle`
  → "JavaScript runtime error: The system cannot locate the resource specified" at line 12.
  No try/catch, no status-code check.
- **Impact:** WSH error dialog on every failed device-control click.
- **Wave:** 0 (CRITICAL/operational) — actually HIGH, but block 1 of Wave 0
- **Effort:** S
- **Confidence:** Confirmed (executed)

### 3.3 MEDIUM

#### QA-003 — `ha-control.js` uses synchronous XHR with no timeout
- **Source IDs:** LIQUIDGLASS-003
- **File:** `@Resources/ha-control.js.example:9`
- **Impact:** `cscript.exe` hangs indefinitely if HA accepts TCP but never responds.
- **Wave:** 2
- **Effort:** S
- **Confidence:** Strong

#### QA-004 — `ha-control.js` hardcodes HTTP — no HTTPS support
- **Source IDs:** LIQUIDGLASS-004
- **File:** `@Resources/ha-control.js.example:9`
- **Observed:** `Microsoft.XMLHTTP` ActiveXObject supports HTTP only. Live version confirmed
  at `http://192.168.4.110:8123/...`. The `.ps1` alternative handles HTTPS; the `.js` does not.
- **Impact:** All device control broken if HA uses HTTPS.
- **Wave:** 1 (security)
- **Effort:** M
- **Confidence:** Strong

#### QA-005 — Light state meters map "unavailable" → "Off"
- **Source IDs:** LIQUIDGLASS-005
- **File:** `LiquidGlass.ini:954, 984, 1014, 1044`
- **Impact:** Unavailable lights display "Off" (indistinguishable from actually-off).
- **Wave:** 3 (UX)
- **Effort:** S
- **Confidence:** Confirmed

### 3.4 LOW

| QA-ID | Title | File | Wave | Effort |
|---|---|---|---|---|
| QA-006 | `MeasureSensorPct` defined but never referenced (dead code) | `LiquidGlass.ini:196-199` | 4 | S |
| QA-007 | `UNIT_TEMP` duplicated with conflicting values (`F` vs `°F`) | `LiquidGlass.ini:4`, `Settings.inc.example:28` | 3 | S |
| QA-008 | Media state meters don't handle "unavailable" | `LiquidGlass.ini:1089,1119,1149,1179` | 3 | S |
| QA-009 | `ha-control.ps1.example` is dead code, not referenced | `@Resources/ha-control.ps1.example` | 4 | S |
| QA-010 | `entityId` concatenated into JSON without escaping | `@Resources/ha-control.js.example:12` | 1 | S |
| QA-011 | `ha-control.ps1.example` silently swallows errors | `@Resources/ha-control.ps1.example:22` | 2 | S |
| QA-012 | `.qa-tmp/` untracked, not in `.gitignore` | `.gitignore` | 4 | S |
| QA-013 | Weather condition Substitute has no catch-all | `LiquidGlass.ini:900` | 3 | M |
| QA-014 | `MeterDot` HA status indicator always green | `LiquidGlass.ini:831-832` | 3 | M |

### 3.5 INFO (verified-clean categories & coverage notes)

- **INFO-001:** Unused variables in `Settings.inc.example` (`LIGHT_LABEL`, `PRESENCE_LABEL`,
  `SENSOR_LABEL`, `PLUGIN_PATH`) — `grep` in `LiquidGlass.ini` returns 0 matches.
- **INFO-002:** No automated test coverage — no test files, no CI, no framework.
- **INFO-003:** Clean clone: no build system to verify (Rainmeter app required, not available).
- **INFO-004:** `.gitignore` properly excludes `Settings.inc`, `ha-control.js`,
  `ha-control.ps1`, `states.md`. `git grep` for secrets in tracked files returns 0 matches.
- **INFO-005:** `noise.png` (141,875 bytes) is a real PNG, not an LFS pointer.
- **INFO-006:** `git fsck --full` clean; single commit `a6bbcc7` on `main`.
- **INFO-007:** No duplicate section names; all 12 `MeasureName=` references valid.

### 3.6 Agent Corrections & False Premises

_None._ Phase 1 counts reconciled exactly.

## 4. Cross-Repo Systemic Patterns

Single-repo campaign. No cross-repo patterns. Themes 1–19 from the standard checklist were
reviewed for single-repo applicability:

1. **Repository as web root**: N/A (not a web project).
2. **Live secrets in history**: Clean — no secrets in tracked files.
3. **Auth fails open**: N/A (no server-side auth in this project; HA token is client-side).
4. **SSRF**: N/A (no server-side URL fetching).
5–10. N/A (no web app, no CI, no containers).
11. **Clean-clone build**: N/A (no build system).
14. **Timezone handling**: N/A (Rainmeter uses system locale).
17. **Timezone**: N/A.
19. **Zero test coverage**: **Confirmed** — no tests exist (covered as INFO-002).

## 5. Fix Wave Plan

| Wave | Scope | Findings | Effort | Test? |
|---|---|---|---|---|
| 0 | CRITICAL | _(none)_ | — | — |
| 0 | Blockers | QA-002 (no error handling in ha-control.js) | S | cscript execution |
| 1 | Security | QA-004 (HTTPS), QA-010 (entityId escaping) | M | cscript execution |
| 2 | Data integrity | QA-001 (isInt crashes), QA-011 (ps1 silent fail) | S | cscript execution |
| 3 | Correctness/UX | QA-005 (unavailable→Off), QA-007 (UNIT_TEMP), QA-008 (media unavailable), QA-013 (weather catch-all), QA-014 (MeterDot) | S+M | Visual (Rainmeter) |
| 4 | Code health | QA-006 (dead measure), QA-009 (dead ps1), QA-012 (.gitignore), INFO-001 (unused vars) | S | Static review |

### 5.1 "Verify first"

QA-002 and QA-003 require cscript execution to verify. The existing cscript pre-flight confirmed
the runtime error is reproducible. Fixes should be verified by re-running cscript with dummy args.

### 5.2 Cross-cutting constraints

- **No Rainmeter runtime** — UI/UX findings (QA-005, QA-007, QA-008, QA-013, QA-014) can only
  be verified by loading the skin in Rainmeter 4.5+ on Windows.
- **No Docker** — N/A (no Dockerfile).
- **Local path** (not SMB) — toolchain false-pass trap does not apply.
- **Never push** — all changes stay in working tree for owner review.

## 6. Verification Strategy

### Build / type gates
- None — Rainmeter skins have no build step.
- `cscript //nologo //E:jscript <file>` to verify JScript syntax after fixes.
- Manual review of INI structure after edits.

### Known environment blockers
- No Rainmeter runtime — cannot visually verify skin loading.
- No HA instance reachable (192.168.4.110) — cannot test live plugin measures.
- Git cosmetic warning from `core.fsccache=true` — no impact on findings.

### Runtime probes
- `cscript //nologo //E:jscript @Resources/ha-control.js.example dummy.test.service.test`
  — should exit cleanly (exit 0 or 1 with message) after fix, instead of throwing.
- Port range 18100–18120: N/A (no local server to start).

### Frontend console-error bar
- N/A — Rainmeter skins do not have a browser console. The equivalent is Rainmeter's log
  (accessible via right-click → "About" → "Log"). Cannot be tested in this environment.

### Regression tests
- Add `cscript //nologo //E:jscript` syntax check to `.qa-tmp/` as a pre-flight gate.
- No existing test framework — `node:test` is not applicable (Rainmeter skins are not Node).
- Document the cscript check in `README.md` or a `scripts/` directory.

### Constraints
- Live config files (`Settings.inc`, `ha-control.js`, `ha-control.ps1`) are gitignored and
  contain real secrets — do NOT read or modify these. Only test `.example` files.

## 7. Risks, Unknowns, and Questions for the owner

### Coverage gaps consolidated by theme
- Rainmeter runtime behavior: 7 findings (QA-005, QA-007, QA-008, QA-013, QA-014) cannot be
  dynamically verified without loading the skin in Rainmeter 4.5+.

### Findings marked Strong or Suspected (NOT confirmed)
- QA-007 (UNIT_TEMP duplication): **Strong** — variable resolution order is deterministic in
  Rainmeter, but the actual skin behavior was not tested (no Rainmeter runtime).
- QA-001 (isInt crashes): **Strong** — BANK.md documents the exact crash, but was not
  reproduced in this environment (no HA plugin to trigger the measure).

### Open questions for the owner (numbered decision list)
1. **Q:** Should `ha-control.ps1.example` be removed (QA-009) or kept as a documented
   alternative? The `.ps1` supports HTTPS while the `.js` does not (QA-004).
2. **Q:** The `MeterDot` status indicator (QA-014) was always-green. Should I add a dynamic
   HA-availability measure to make it red when disconnected? This requires a working HA
   plugin measure — can it be tested?
3. **Q:** Should I remove the dead `MeasureSensorPct` (QA-006) or wire it to a new meter
   (e.g., a sensor bar visualization)?
4. **Q:** The `isInt=true` fix for weather/humidity/battery (QA-001) — should I also audit
   `MeasureClimateTemp:isInt=true` (line 148) and `MeasureSelectSmartPlugPowerOnBehavior:isInt=true`
   (line 471) and `MeasureTodoShoppingList:isInt=true` (line 759)? These currently have
   integer values in `states.md` but could change.

### Corrections to assumptions
- None.

## 8. Pre-Existing Uncommitted Work Warning

```
?? .qa-tmp/
```

The only untracked items are `.qa-tmp/ha-control-check.js` and
`.qa-tmp/ha-control.js.example.js` — both identical copies of `ha-control.js.example`,
created during this campaign's pre-flight. No tracked files are dirty (`git status
--porcelain --untracked-files=no` returns clean). Fix agents must not touch `.qa-tmp/`
contents and should leave `.qa-tmp/` out of any `git add`.

## 9. Appendices

### 9.1 Per-repo report index
- `QA/reports/HASSIO-Rainmeter-Widget.md` (Phase 1 report)

### 9.2 Repo path map (GitHub ↔ local)
| GitHub | Local path |
|---|---|
| HASSIO-Rainmeter-Widget | `C:\Users\brgjr\Documents\Rainmeter\Skins\LiquidGlass` |

### 9.3 Severity legend
| Label | Meaning |
|---|---|
| CRITICAL | Data loss, RCE/auth bypass, leaked private key/secret, exploitable on a public host |
| HIGH | Security weakness, broken build, data corruption, silent wrong answers |
| MEDIUM | Real defect with a workaround; UX breakage; resource exhaustion |
| LOW | Code smell, dead code, minor inconsistency, stale dep |
| INFO | Observation, improvement idea, or explicitly-covered-and-clean category |

---

## 🚦 GATE — Stop for owner approval

**Phase 3 (fixes + adversarial re-review) starts only on explicit approval.**

The QA report is complete with **21 findings: 0 CRITICAL, 2 HIGH, 3 MEDIUM, 9 LOW, 7 INFO**.

Top 3 findings to fix first:
1. **QA-002 (HIGH):** `ha-control.js` crashes with unhandled error on every failed click.
2. **QA-001 (HIGH):** `isInt=true` on 4 measures causes documented crashes.
3. **QA-004 (MEDIUM):** `ha-control.js` doesn't support HTTPS — broken device control for HTTPS HA.

Top 3 questions for the owner:
1. Remove or keep `ha-control.ps1.example` (dead code, but it supports HTTPS)?
2. Add dynamic HA-status to `MeterDot` (QA-014)?
3. Remove `MeasureSensorPct` (QA-006) or wire it to a new meter?
