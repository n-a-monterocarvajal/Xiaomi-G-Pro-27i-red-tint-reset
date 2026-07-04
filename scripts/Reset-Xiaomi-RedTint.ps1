param(
    [string]$ControlMyMonitor = (Join-Path $PSScriptRoot "ControlMyMonitor.exe"),
    [string]$Monitor = "Primary",
    [int]$DelayMs = 500,
    [switch]$Quiet
)

function Write-Info {
    param([string]$Message)

    if (-not $Quiet) {
        Write-Host $Message
    }
}

if (-not (Test-Path $ControlMyMonitor)) {
    throw "ControlMyMonitor.exe was not found. Place it next to this script or pass -ControlMyMonitor with its full path."
}

if (-not $Quiet) {
    Clear-Host
    Write-Host "Xiaomi G Pro 27i - Red Tint Reset" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Target monitor:"
    Write-Host "  $Monitor"
    Write-Host ""
    Write-Host "Applying VCP DC / Display Application = 0..."
    Write-Host ""
    Write-Host "Note: on the tested unit, this command may reset the monitor OSD color space/gamut selection to Native." -ForegroundColor Yellow
    Write-Host ""
}

& $ControlMyMonitor /SetValue $Monitor DC 0

Start-Sleep -Milliseconds $DelayMs

Write-Info "Done. Reapplied VCP DC = 0."
