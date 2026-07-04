param(
    [string]$ControlMyMonitor = (Join-Path $PSScriptRoot "ControlMyMonitor.exe"),
    [string]$Monitor = "Primary",
    [string]$BaselineColorSpace = "DCI-P3",
    [int[]]$Values = @(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15),
    [int]$DelayMs = 1200,
    [string]$OutputDir = (Join-Path $PSScriptRoot "test-results"),
    [switch]$NoManualBaselineReset
)

function Ask-Observation {
    param(
        [int]$Value
    )

    Write-Host ""
    Write-Host "Inspect the monitor OSD color-space/gamut setting now." -ForegroundColor Cyan
    Write-Host "Expected labels may include: Native, Adobe RGB, DCI-P3, sRGB, No change, Unknown"
    $space = Read-Host "Visible OSD color space after VCP DC = $Value"
    $changed = Read-Host "Did the color space change from baseline '$BaselineColorSpace'? [Y/N/Unknown]"
    $redTint = Read-Host "Red tint visible? [Y/N/Unknown]"
    $notes = Read-Host "Notes, if any"

    return [pscustomobject]@{
        Timestamp = (Get-Date).ToString("s")
        Monitor = $Monitor
        BaselineColorSpace = $BaselineColorSpace
        VCPCode = "DC"
        Value = $Value
        ObservedColorSpace = $space
        ChangedFromBaseline = $changed
        RedTintVisible = $redTint
        Notes = $notes
    }
}

function Apply-DCValue {
    param([int]$Value)

    Write-Host ""
    Write-Host "Applying VCP DC / Display Application = $Value" -ForegroundColor Yellow
    & $ControlMyMonitor /SetValue $Monitor DC $Value
    Start-Sleep -Milliseconds $DelayMs
}

Clear-Host
Write-Host "Xiaomi G Pro 27i - Color Space Only Test" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target monitor:"
Write-Host "  $Monitor"
Write-Host ""
Write-Host "This script tests only the candidate currently observed to affect the OSD color space:" -ForegroundColor Cyan
Write-Host "  VCP DC / Display Application"
Write-Host ""
Write-Host "It does NOT test brightness, contrast, input source, power mode, or VCP 14 color preset." -ForegroundColor Green
Write-Host "It does NOT touch VCP 60 / Input Select or VCP D6 / Power Mode." -ForegroundColor Green
Write-Host ""
Write-Host "Known observation on one tested unit: DC = 0 can return the OSD color space from DCI-P3 to Native." -ForegroundColor Yellow
Write-Host ""
Write-Host "Baseline color space for this test: $BaselineColorSpace" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $ControlMyMonitor)) {
    throw "ControlMyMonitor.exe was not found. Place it next to this script or pass -ControlMyMonitor with its full path."
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outFile = Join-Path $OutputDir "color-space-only-dc-test-$timestamp.csv"
$results = New-Object System.Collections.Generic.List[object]

Write-Host "How to use this test:" -ForegroundColor Cyan
Write-Host "  1. Before each value, set the monitor OSD color space to the baseline you want to test."
Write-Host "  2. The script applies one VCP DC value."
Write-Host "  3. You inspect the OSD and record whether it changed to Native, Adobe RGB, DCI-P3, sRGB, etc."
Write-Host ""
Write-Host "For the current hypothesis, use BaselineColorSpace = DCI-P3 first."
Write-Host "Later you can repeat with Adobe RGB and sRGB."
Write-Host ""
Read-Host "Press Enter to begin"

foreach ($value in $Values) {
    if (-not $NoManualBaselineReset) {
        Write-Host ""
        Write-Host "Set the monitor OSD color space to baseline: $BaselineColorSpace" -ForegroundColor Cyan
        Read-Host "Press Enter once the OSD baseline is restored"
    }

    Apply-DCValue -Value $value
    $obs = Ask-Observation -Value $value
    $results.Add($obs)
    $results | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8

    Write-Host ""
    $action = Read-Host "Enter = next value, S = stop and save, Q = quit"
    if ($action -match "^[sSqQ]$") {
        break
    }
}

Write-Host ""
Write-Host "Test finished." -ForegroundColor Green
Write-Host "Results saved to:"
Write-Host "  $outFile"
Write-Host ""
Write-Host "Recommended final check:" -ForegroundColor Cyan
Write-Host "  Re-open the monitor OSD and manually restore your preferred color space if needed."
Write-Host ""
Read-Host "Press Enter to close"
