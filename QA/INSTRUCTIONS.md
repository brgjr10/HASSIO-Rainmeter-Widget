# Repo QA Campaign — bug-qa-20261006

## Repo table

| GitHub | Local path | Commit | Branch | Dirty |
|---|---|---|---|---|
| HASSIO-Rainmeter-Widget | `C:\Users\brgjr\Documents\Rainmeter\Skins\LiquidGlass` | `a6bbcc7` | `main` | 2 untracked files in `.qa-tmp/` (leftover from campaign setup; `.qa-tmp/` is NOT in `.gitignore`) |

Remote: `https://github.com/brgjr10/HASSIO-Rainmeter-Widget.git`

## What this project is

A **Rainmeter skin** (INI-based widget) for Home Assistant. Not a Node/Python/Electron/FastAPI
project — there is no `package.json`, no `Dockerfile`, no `requirements.txt`, no CI, no test
framework. The "runtime" is the Rainmeter desktop application (Windows-only, 4.5+).

**Tracked files (10):**
- `LiquidGlass.ini` — skin definition: 44 HA-plugin measures + 30+ meters
- `@Resources/Settings.inc.example` — template config (placeholders for HA server, token, entity IDs)
- `@Resources/ha-control.js.example` — JScript helper for HA REST API service calls
- `@Resources/ha-control.ps1.example` — PowerShell alternative helper (not wired into the skin)
- `@Resources/noise.png` — grain texture (real PNG, not an LFS pointer)
- `README.md`, `STRUCTURE.md`, `BANK.md`, `HARESTAPI.md`, `.gitignore`

**Untracked working-tree files (not in repo):**
- `@Resources/Settings.inc` (gitignored — contains real HA token)
- `@Resources/ha-control.js` (gitignored — contains real server + token)
- `@Resources/ha-control.ps1` (gitignored — contains real server + token)
- `states.md` (gitignored — live HA entity-state dump)
- `.qa-tmp/` (untracked — NOT in .gitignore, could be accidentally committed)

## Environment constraints

- **No Rainmeter runtime** in this environment. The skin cannot be loaded/verified visually.
  All `LiquidGlass.ini` analysis is static.
- **`cscript.exe` available** — can syntax-check and execute `ha-control.js` (it throws a
  runtime error when HA is unreachable; this is itself a finding).
- **No Docker daemon** — no Dockerfile to review anyway.
- **Git path is local** (`C:\...`), not SMB/UNC — the `tsc`/`pytest` false-pass trap from
  `references/ENVIRONMENT.md` does not apply (no such tools in this project).
- `git status` emits a cosmetic warning (`could not open directory 'LiquidGlass.ini /'`) caused
  by `core.fscache=true`. `git fsck` is clean. The warning does not affect any finding.

## Structural traps to verify first

1. **Clean-clone build**: N/A — no build system. The "build" is Rainmeter loading the INI.
   Verified all `MeasureName=` references match defined measure names. No tracked file imports
   an untracked module (no import system at all in Rainmeter INI).
2. **Committed build output orphaning source**: N/A — no build artifacts tracked.
3. **Secrets reachable from build**: `.gitignore` covers the live config files. `.example`
   copies contain placeholders only. Verified via `git grep` — no real secrets in tracked files.

## Test taxonomy (adapted for Rainmeter)

Categories A–I from `references/TEST_AGENT.md` apply with these adaptations:
- **A (Build & deps)**: No build system; static INI + JScript analysis only.
- **B (Correctness)**: Rainmeter measure logic, Substitute chains, boundary conditions.
- **C (Input validation & injection)**: JSON body construction in `ha-control.js`.
- **D (Security & secrets)**: Gitignore coverage, token storage, HTTPS support.
- **E (Frontend/UI)**: Rainmeter-specific: substitute mappings, dead code, palette usage.
- **F (Persistence)**: Settings storage, dirty-file risk.
- **G (Performance)**: Update frequencies, sync blocking, unused measures.
- **H (Operational)**: Error handling in `ha-control.js`/`.ps1`, no logging.
- **I (Cross-cutting)**: Single project, no subprojects.

## How to run tests

- `cscript.exe //nologo //E:jscript <file>` — syntax-check and execute JScript helpers.
- Static review of `LiquidGlass.ini` for measure/meter correctness.
- `git grep` for secret patterns in tracked files.
- `git ls-files` to verify tracked file set.
