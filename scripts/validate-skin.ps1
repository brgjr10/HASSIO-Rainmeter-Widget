<#
.SYNOPSIS
    Automated validation for the LiquidGlass Rainmeter skin.
.DESCRIPTION
    Performs static checks on LiquidGlass.ini, ha-control.js.example,
    Settings.inc.example, and .gitignore.
    Run from the repo root: powershell -File scripts\validate-skin.ps1
#>

param(
    [string]$RepoPath = (Get-Location)
)

$ErrorActionPreference = 'Continue'
$failures = 0

Write-Host "=== LiquidGlass Skin Validation ===" -ForegroundColor Cyan
Write-Host ""

# --- Paths ---
$iniPath = Join-Path $RepoPath "LiquidGlass.ini"
$jsPath = Join-Path $RepoPath "@Resources\ha-control.js.example"
$settingsPath = Join-Path $RepoPath "@Resources\Settings.inc.example"
$gitignorePath = Join-Path $RepoPath ".gitignore"
$ps1ExamplePath = Join-Path $RepoPath "@Resources\ha-control.ps1.example"

# --- Check 1: LiquidGlass.ini exists ---
if (-not (Test-Path $iniPath)) {
    Write-Host "FAIL: LiquidGlass.ini not found at $iniPath" -ForegroundColor Red
    $failures++
} else {
    Write-Host "PASS: LiquidGlass.ini found" -ForegroundColor Green
}

# --- Check 2: isInt=true only on guaranteed-integer measures ---
# After fixes, only 6 active isInt=true remain (3 brightness, select, todo, effect speed).
# Commented-out forecast measures (prefixed with ;) are excluded.
if (Test-Path $iniPath) {
    $isIntActive = Select-String -Path $iniPath -Pattern '^[^;]*isInt=true' -AllMatches
    $isIntCount = $isIntActive.Matches.Count
    Write-Host "INFO: Found $isIntCount active occurrences of isInt=true" -ForegroundColor Yellow
    if ($isIntCount -ne 6) {
        Write-Host "FAIL: Expected 6 active isInt=true, found $isIntCount" -ForegroundColor Red
        $failures++
    } else {
        Write-Host "PASS: isInt=true count correct (6 active)" -ForegroundColor Green
    }
}

# --- Check 3: No unavailable:Off in substitutes ---
if (Test-Path $iniPath) {
    $iniContent = Get-Content $iniPath -Raw
    $offMatches = [regex]::Matches($iniContent, 'unavailable.*Off')
    if ($offMatches.Count -gt 0) {
        $msg = "FAIL: Found " + $offMatches.Count + " unavailable-Off patterns - should be unavailable-Unavailable"
        Write-Host $msg -ForegroundColor Red
        $failures++
    } else {
        Write-Host "PASS: No unavailable-Off patterns found" -ForegroundColor Green
    }
}

# --- Check 4: All substitutes use unavailable:Unavailable (4 media + 4 light = 8 total) ---
if (Test-Path $iniPath) {
    $iniContent = Get-Content $iniPath -Raw
    $count = ([regex]::Matches($iniContent, 'Unavailable')).Count
    Write-Host "INFO: Found $count occurrences of Unavailable" -ForegroundColor Yellow
    if ($count -ne 8) {
        $msg = "FAIL: Expected 8 Unavailable (4 media + 4 light), found " + $count
        Write-Host $msg -ForegroundColor Red
        $failures++
    } else {
        Write-Host "PASS: All 4 media + 4 light substitutes include Unavailable" -ForegroundColor Green
    }
}

# --- Check 5: UNIT_TEMP appears exactly once in [Variables] (user config) ---
if (Test-Path $iniPath) {
    $unitTemp = Select-String -Path $iniPath -Pattern "^UNIT_TEMP=(C|F)$" -AllMatches
    $count = $unitTemp.Matches.Count
    if ($count -eq 1) {
        Write-Host "PASS: UNIT_TEMP configured once" -ForegroundColor Green
    } elseif ($count -eq 0) {
        Write-Host "FAIL: UNIT_TEMP missing from [Variables]" -ForegroundColor Red
        $failures++
    } else {
        Write-Host "FAIL: UNIT_TEMP appears $count times (expected 1)" -ForegroundColor Red
        $failures++
    }
}

# --- Check 6: MeasureSensorPct section removed ---
if (Test-Path $iniPath) {
    $searchResult = Select-String -Path $iniPath -Pattern "\[MeasureSensorPct\]" -SimpleMatch
    if ($searchResult) {
        Write-Host "FAIL: MeasureSensorPct section still present" -ForegroundColor Red
        $failures++
    } else {
        Write-Host "PASS: MeasureSensorPct section removed" -ForegroundColor Green
    }
}

# --- Check 7: No dangling MeasureName references ---
if (Test-Path $iniPath) {
    $iniContent = Get-Content $iniPath -Raw
    $sectionNames = [System.Collections.Generic.HashSet[string]]::new()
    $iniContent -split "`n" | ForEach-Object {
        if ($_ -match '^\[(Measure\w+|Meter\w+)\]') {
            $sectionNames.Add($matches[1]) | Out-Null
        }
    }
    $dangling = 0
    $iniContent -split "`n" | ForEach-Object {
        if ($_ -match 'MeasureName=(\w+)') {
            if (-not $sectionNames.Contains($matches[1])) {
                Write-Host "FAIL: Dangling MeasureName reference: $($matches[1])" -ForegroundColor Red
                $dangling++
            }
        }
    }
    if ($dangling -eq 0) {
        Write-Host "PASS: All MeasureName references valid" -ForegroundColor Green
    } else {
        $failures++
    }
}

# --- Check 8: No duplicate section names ---
if (Test-Path $iniPath) {
    $iniContent = Get-Content $iniPath -Raw
    $sections = @()
    $iniContent -split "`n" | ForEach-Object {
        if ($_ -match '^\[(Measure\w+|Meter\w+)\]') {
            $sections += $matches[1]
        }
    }
    $dupes = $sections | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($dupes) {
        Write-Host "FAIL: Duplicate sections found" -ForegroundColor Red
        $failures++
    } else {
        Write-Host "PASS: No duplicate section names" -ForegroundColor Green
    }
}

# --- Check 9: ha-control.js.example uses WinHttp + try/catch + SetTimeouts ---
if (Test-Path $jsPath) {
    $jsContent = Get-Content $jsPath -Raw
    if ($jsContent -match "MSXML2\.ServerXMLHTTP\.6\.0") {
        Write-Host "PASS: ha-control.js.example uses MSXML2.ServerXMLHTTP.6.0 (HTTPS-capable)" -ForegroundColor Green
    } else {
        Write-Host "FAIL: ha-control.js.example does not use MSXML2.ServerXMLHTTP.6.0" -ForegroundColor Red
        $failures++
    }
    if ($jsContent -match "setTimeouts") {
        Write-Host "PASS: ha-control.js.example has setTimeouts (timeout)" -ForegroundColor Green
    } else {
        Write-Host "FAIL: ha-control.js.example missing setTimeOuts" -ForegroundColor Red
        $failures++
    }
    if ($jsContent -match "try" -and $jsContent -match "catch") {
        Write-Host "PASS: ha-control.js.example has try/catch" -ForegroundColor Green
    } else {
        Write-Host "FAIL: ha-control.js.example missing try/catch" -ForegroundColor Red
        $failures++
    }
    if ($jsContent -match "escapeJson") {
        Write-Host "PASS: ha-control.js.example escapes entityId in JSON" -ForegroundColor Green
    } else {
        Write-Host "FAIL: ha-control.js.example does not escape entityId" -ForegroundColor Red
        $failures++
    }
    if ($jsContent -match "HA_SSL" -and $jsContent -match "HA_PORT") {
        Write-Host "PASS: ha-control.js.example has HA_SSL and HA_PORT config vars" -ForegroundColor Green
    } else {
        Write-Host "FAIL: ha-control.js.example missing HA_SSL or HA_PORT config vars" -ForegroundColor Red
        $failures++
    }
    if ($jsContent -match "Microsoft\.XMLHTTP") {
        Write-Host "FAIL: ha-control.js.example still uses Microsoft.XMLHTTP" -ForegroundColor Red
        $failures++
    } else {
        Write-Host "PASS: ha-control.js.example no longer uses Microsoft.XMLHTTP" -ForegroundColor Green
    }
}

# --- Check 10: .gitignore contains .qa-tmp ---
if (Test-Path $gitignorePath) {
    $gitignore = Get-Content $gitignorePath -Raw
    if ($gitignore -match "\.qa-tmp") {
        Write-Host "PASS: .gitignore contains .qa-tmp" -ForegroundColor Green
    } else {
        Write-Host "FAIL: .gitignore missing .qa-tmp" -ForegroundColor Red
        $failures++
    }
}

# --- Check 11: Settings.inc.example has no unused config vars ---
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw
    $unusedVars = @("LIGHT_LABEL", "PRESENCE_LABEL", "SENSOR_LABEL", "PLUGIN_PATH")
    $foundUnused = @()
    foreach ($v in $unusedVars) {
        if ($settings -match "$v=") {
            $foundUnused += $v
        }
    }
    if ($foundUnused.Count -eq 0) {
        Write-Host "PASS: Unused config variables removed from Settings.inc.example" -ForegroundColor Green
    } else {
        $names = $foundUnused -join ", "
        Write-Host "FAIL: Unused config variables still present: $names" -ForegroundColor Red
        $failures++
    }
}

# --- Check 12: ha-control.ps1.example deleted ---
if (Test-Path $ps1ExamplePath) {
    Write-Host "FAIL: ha-control.ps1.example still exists" -ForegroundColor Red
    $failures++
} else {
    Write-Host "PASS: ha-control.ps1.example removed" -ForegroundColor Green
}

# --- Check 13: No secrets in tracked files ---
$secretPattern = 'YOUR_HA_TOKEN_HERE|Bearer eyJ|^\d{4}[-|]\d{4}[-|]\d{4}[-|]\d{4}'
$trackedFiles = git -C $RepoPath ls-files 2>$null | Where-Object { $_ -match '\.(js|ini|inc|ps1|md|json)$' }
if ($trackedFiles) {
    $secretHits = @()
    foreach ($f in $trackedFiles) {
        $fullPath = Join-Path $RepoPath $f
        if (Test-Path $fullPath) {
            $match = Select-String -Path $fullPath -Pattern $secretPattern -AllMatches 2>$null
            if ($match -and $match.Matches.Count -gt 0) {
                $hitDesc = $f + " - " + $match.Matches.Count + " hits"
                $secretHits += $hitDesc
            }
        }
    }
    if ($secretHits.Count -eq 0) {
        Write-Host "PASS: No secrets found in tracked source files" -ForegroundColor Green
    } else {
        $names = $secretHits -join ", "
        Write-Host "FAIL: Potential secrets in tracked files: $names" -ForegroundColor Red
        $failures++
    }
} else {
    Write-Host "INFO: Could not enumerate tracked files" -ForegroundColor Yellow
}

Write-Host ""
if ($failures -eq 0) {
    Write-Host "=== ALL CHECKS PASSED ===" -ForegroundColor Green
    exit 0
} else {
    Write-Host "=== $failures CHECK(S) FAILED ===" -ForegroundColor Red
    exit 1
}
