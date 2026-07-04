param(
    [string]$ControlMyMonitor = (Join-Path $PSScriptRoot "ControlMyMonitor.exe"),
    [string]$Monitor = "Primary",
    [int]$DelayMs = 1200,
    [string]$OutputDir = (Join-Path $PSScriptRoot "test-results"),
    [int[]]$DCValues = @(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15),
    [int[]]$ColorPresetValues = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12),
    [switch]$SkipDC,
    [switch]$SkipColorPreset14
)

function Ask-Observation {
    param(
        [string]$Code,
        [int]$Value
    )

    Write-Host ""
    Write-Host "Inspect the monitor OSD now." -ForegroundColor Cyan
    Write-Host "Suggested labels: Native, Adobe RGB, DCI-P3, sRGB, No change, Unknown"
    $space = Read-Host "Visible OSD color space after VCP $Code = $Value"
    $redTint = Read-Host "Red tint visible? [Y/N/Unknown]"
    $notes = Read-Host "Notes, if any"

    return [pscustomobject]@{
        Timestamp = (Get-Date).ToString("s")
        Monitor = $Monitor
        VCPCode = $Code
        Value = $Value
        ObservedColorSpace = $space
        RedTintVisible = $redTint
        Notes = $notes
    }
}

function Apply-VCP {
    param(
        [string]$Code,
        [int]$Value,
        [string]$Description
    )

    Write-Host ""
    Write-Host "Applying: $Description" -ForegroundColor Yellow
    Write-Host "VCP $Code = $Value"
    & $ControlMyMonitor /SetValue $Monitor $Code $Value
    Start-Sleep -Milliseconds $DelayMs
}

Clear-Host
Write-Host "Xiaomi G Pro 27i - Color Space / Gamut VCP test" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target monitor:"
Write-Host "  $Monitor"
Write-Host ""
Write-Host "This script tests selected VCP values and asks you to record what the monitor OSD shows."
Write-Host "It does not touch VCP 60 / Input Select or VCP D6 / Power Mode." -ForegroundColor Green
Write-Host ""
Write-Host "Main candidates:"
Write-Host "  DC = Display Application"
Write-Host "  14 = Select Color Preset"
Write-Host ""
Write-Host "Known observation on one tested unit: DC = 0 can return the OSD color space from DCI-P3 to Native." -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $ControlMyMonitor)) {
    throw "ControlMyMonitor.exe was not found. Place it next to this script or pass -ControlMyMonitor with its full path."
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outFile = Join-Path $OutputDir "color-space-vcp-test-$timestamp.csv"
$results = New-Object System.Collections.Generic.List[object]

Write-Host "Before starting, set the monitor OSD to the color space you want to test from." -ForegroundColor Cyan
Write-Host "For example: DCI-P3, Adobe RGB, sRGB, or Native."
Write-Host ""
Read-Host "Press Enter to begin"

if (-not $SkipDC) {
    Write-Host ""
    Write-Host "Testing VCP DC / Display Application values..." -ForegroundColor Cyan

    foreach ($value in $DCValues) {
        Apply-VCP -Code "DC" -Value $value -Description "Display Application candidate"
        $obs = Ask-Observation -Code "DC" -Value $value
        $results.Add($obs)
        $results | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8

        $action = Read-Host "Enter = continue, S = skip remaining DC values, Q = quit"
        if ($action -match "^[qQ]$") { break }
        if ($action -match "^[sS]$") { break }
    }
}

if (-not $SkipColorPreset14) {
    Write-Host ""
    Write-Host "Testing VCP 14 / Select Color Preset values..." -ForegroundColor Cyan
    Write-Host "This is a standard-ish color preset control, but it may map to color temperature rather than gamut." -ForegroundColor Yellow

    foreach ($value in $ColorPresetValues) {
        Apply-VCP -Code "14" -Value $value -Description "Select Color Preset candidate"
        $obs = Ask-Observation -Code "14" -Value $value
        $results.Add($obs)
        $results | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8

        $action = Read-Host "Enter = continue, S = skip remaining VCP 14 values, Q = quit"
        if ($action -match "^[qQ]$") { break }
        if ($action -match "^[sS]$") { break }
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
