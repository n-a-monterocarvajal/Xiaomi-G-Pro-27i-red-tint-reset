param(
    [string]$ControlMyMonitor = (Join-Path $PSScriptRoot "ControlMyMonitor.exe"),
    [string]$Monitor = "Primary",
    [string[]]$ColorSpaces = @("Native", "Adobe RGB", "DCI-P3", "sRGB"),
    [int]$SettleSeconds = 2,
    [int]$CaptureTimeoutSeconds = 15,
    [string]$OutputRoot = (Join-Path $PSScriptRoot "manual-color-space-captures")
)

function Normalize-Name {
    param([string]$Name)
    if ($null -eq $Name) { return "" }
    return ($Name.ToLowerInvariant() -replace "[^a-z0-9]", "")
}

function Find-PropertyName {
    param(
        [object]$Object,
        [string[]]$Candidates
    )

    $properties = $Object.PSObject.Properties.Name
    foreach ($candidate in $Candidates) {
        $normalizedCandidate = Normalize-Name $candidate
        foreach ($property in $properties) {
            if ((Normalize-Name $property) -eq $normalizedCandidate) {
                return $property
            }
        }
    }

    return $null
}

function Get-PropertyValue {
    param(
        [object]$Object,
        [string[]]$Candidates
    )

    $propertyName = Find-PropertyName -Object $Object -Candidates $Candidates
    if ($null -eq $propertyName) { return $null }
    return [string]$Object.$propertyName
}

function Sanitize-FileName {
    param([string]$Value)
    return ($Value -replace "[^a-zA-Z0-9._-]", "_")
}

function Invoke-ControlMyMonitorSave {
    param(
        [string]$Mode,
        [string]$OutputPath
    )

    $arguments = @($Mode, $OutputPath, $Monitor)

    Write-Host "Running: `"$ControlMyMonitor`" $($arguments -join ' ')" -ForegroundColor DarkGray

    $process = Start-Process -FilePath $ControlMyMonitor -ArgumentList $arguments -NoNewWindow -PassThru -Wait

    $deadline = (Get-Date).AddSeconds($CaptureTimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if ((Test-Path $OutputPath) -and ((Get-Item $OutputPath).Length -gt 0)) {
            return
        }
        Start-Sleep -Milliseconds 250
    }

    throw "Capture was not created or remained empty after $CaptureTimeoutSeconds seconds: $OutputPath"
}

function Capture-State {
    param(
        [int]$Index,
        [string]$ColorSpace,
        [string]$Folder
    )

    $safeName = Sanitize-FileName $ColorSpace
    $prefix = "{0:D2}_{1}" -f $Index, $safeName
    $csvPath = Join-Path $Folder "$prefix.csv"
    $txtPath = Join-Path $Folder "$prefix.txt"

    Write-Host ""
    Write-Host "Capturing all readable VCP values for: $ColorSpace" -ForegroundColor Yellow

    Invoke-ControlMyMonitorSave -Mode "/scomma" -OutputPath $csvPath
    Invoke-ControlMyMonitorSave -Mode "/stext" -OutputPath $txtPath

    return [pscustomobject]@{
        Index = $Index
        ColorSpace = $ColorSpace
        CsvPath = $csvPath
        TextPath = $txtPath
    }
}

function Load-VcpSnapshot {
    param([string]$CsvPath)

    $rows = Import-Csv -Path $CsvPath
    $map = @{}

    foreach ($row in $rows) {
        $code = Get-PropertyValue -Object $row -Candidates @("VCP Code", "VCPCode", "Code")
        if ([string]::IsNullOrWhiteSpace($code)) {
            continue
        }

        $name = Get-PropertyValue -Object $row -Candidates @("Name", "VCP Code Name", "VCPCodeName", "Description")
        $current = Get-PropertyValue -Object $row -Candidates @("Current Value", "CurrentValue")
        $maximum = Get-PropertyValue -Object $row -Candidates @("Maximum Value", "MaximumValue")
        $possible = Get-PropertyValue -Object $row -Candidates @("Possible Values", "PossibleValues")
        $readWrite = Get-PropertyValue -Object $row -Candidates @("Read-Write", "Read Write", "ReadWrite")

        $map[$code] = [pscustomobject]@{
            Code = $code
            Name = $name
            CurrentValue = $current
            MaximumValue = $maximum
            PossibleValues = $possible
            ReadWrite = $readWrite
            Raw = $row
        }
    }

    return $map
}

function Compare-Snapshots {
    param(
        [object]$Previous,
        [object]$Current,
        [string]$PreviousLabel,
        [string]$CurrentLabel,
        [string]$OutputFolder
    )

    $previousMap = Load-VcpSnapshot -CsvPath $Previous.CsvPath
    $currentMap = Load-VcpSnapshot -CsvPath $Current.CsvPath

    $codes = @($previousMap.Keys + $currentMap.Keys | Sort-Object -Unique)
    $diffs = New-Object System.Collections.Generic.List[object]

    foreach ($code in $codes) {
        $beforeExists = $previousMap.ContainsKey($code)
        $afterExists = $currentMap.ContainsKey($code)

        if (-not $beforeExists -and $afterExists) {
            $after = $currentMap[$code]
            $diffs.Add([pscustomobject]@{
                From = $PreviousLabel
                To = $CurrentLabel
                VCPCode = $code
                VCPName = $after.Name
                Field = "Presence"
                Before = "<missing>"
                After = "<present>"
            })
            continue
        }

        if ($beforeExists -and -not $afterExists) {
            $before = $previousMap[$code]
            $diffs.Add([pscustomobject]@{
                From = $PreviousLabel
                To = $CurrentLabel
                VCPCode = $code
                VCPName = $before.Name
                Field = "Presence"
                Before = "<present>"
                After = "<missing>"
            })
            continue
        }

        $before = $previousMap[$code]
        $after = $currentMap[$code]
        $fields = @("CurrentValue", "MaximumValue", "PossibleValues", "ReadWrite")

        foreach ($field in $fields) {
            $beforeValue = [string]$before.$field
            $afterValue = [string]$after.$field
            if ($beforeValue -ne $afterValue) {
                $displayName = $before.Name
                if (-not [string]::IsNullOrWhiteSpace($after.Name)) {
                    $displayName = $after.Name
                }

                $diffs.Add([pscustomobject]@{
                    From = $PreviousLabel
                    To = $CurrentLabel
                    VCPCode = $code
                    VCPName = $displayName
                    Field = $field
                    Before = $beforeValue
                    After = $afterValue
                })
            }
        }
    }

    $safePrevious = Sanitize-FileName $PreviousLabel
    $safeCurrent = Sanitize-FileName $CurrentLabel
    $diffCsv = Join-Path $OutputFolder "diff_${safePrevious}_vs_${safeCurrent}.csv"
    $diffTxt = Join-Path $OutputFolder "diff_${safePrevious}_vs_${safeCurrent}.txt"

    if ($diffs.Count -eq 0) {
        "No differences detected between $PreviousLabel and $CurrentLabel." | Set-Content -Path $diffTxt -Encoding UTF8
        "From,To,VCPCode,VCPName,Field,Before,After" | Set-Content -Path $diffCsv -Encoding UTF8
    }
    else {
        $diffs | Export-Csv -Path $diffCsv -NoTypeInformation -Encoding UTF8
        $diffs | Format-Table -AutoSize | Out-String | Set-Content -Path $diffTxt -Encoding UTF8
    }

    return [pscustomobject]@{
        From = $PreviousLabel
        To = $CurrentLabel
        Count = $diffs.Count
        CsvPath = $diffCsv
        TextPath = $diffTxt
        Diffs = $diffs
    }
}

Clear-Host
Write-Host "Xiaomi G Pro 27i - Manual Color Space Capture" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target monitor:"
Write-Host "  $Monitor"
Write-Host ""
Write-Host "This script is read-only." -ForegroundColor Green
Write-Host "It does not set any VCP value. It only captures all monitor VCP values after you manually change the OSD color space."
Write-Host ""
Write-Host "Color spaces to capture:"
foreach ($space in $ColorSpaces) {
    Write-Host "  - $space"
}
Write-Host ""

if (-not (Test-Path $ControlMyMonitor)) {
    throw "ControlMyMonitor.exe was not found. Place it next to this script or pass -ControlMyMonitor with its full path."
}

$runId = Get-Date -Format "yyyyMMdd-HHmmss"
$outputFolder = Join-Path $OutputRoot "manual-color-space-$runId"
New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null

$monitorsFile = Join-Path $outputFolder "00_monitors.txt"
Start-Process -FilePath $ControlMyMonitor -ArgumentList @("/smonitors", $monitorsFile) -NoNewWindow -PassThru -Wait | Out-Null

$observations = New-Object System.Collections.Generic.List[object]
$captures = New-Object System.Collections.Generic.List[object]
$comparisons = New-Object System.Collections.Generic.List[object]

Read-Host "Press Enter to begin the guided manual capture"

$index = 1
foreach ($space in $ColorSpaces) {
    Write-Host ""
    Write-Host "STEP $index - Manual OSD action required" -ForegroundColor Cyan
    Write-Host "Set the monitor OSD color space to: $space" -ForegroundColor Yellow
    Write-Host "Do not change other OSD settings during this step."
    Read-Host "Press Enter after setting the color space to $space"

    if ($SettleSeconds -gt 0) {
        Write-Host "Waiting $SettleSeconds second(s) for the monitor state to settle..."
        Start-Sleep -Seconds $SettleSeconds
    }

    $redTint = Read-Host "Red tint visible in this state? [Y/N/Unknown]"
    $notes = Read-Host "Notes for this state, if any"

    $capture = Capture-State -Index $index -ColorSpace $space -Folder $outputFolder
    $captures.Add($capture)

    $observations.Add([pscustomobject]@{
        Timestamp = (Get-Date).ToString("s")
        Step = $index
        RequestedColorSpace = $space
        RedTintVisible = $redTint
        Notes = $notes
        CsvPath = $capture.CsvPath
        TextPath = $capture.TextPath
    })

    if ($captures.Count -gt 1) {
        $previous = $captures[$captures.Count - 2]
        $current = $captures[$captures.Count - 1]
        $comparison = Compare-Snapshots -Previous $previous -Current $current -PreviousLabel $previous.ColorSpace -CurrentLabel $current.ColorSpace -OutputFolder $outputFolder
        $comparisons.Add($comparison)

        Write-Host ""
        Write-Host "Detected differences from $($previous.ColorSpace) to $($current.ColorSpace): $($comparison.Count)" -ForegroundColor Cyan
        Write-Host "Diff saved to:"
        Write-Host "  $($comparison.TextPath)"
    }

    $observationsPath = Join-Path $outputFolder "observations.csv"
    $observations | Export-Csv -Path $observationsPath -NoTypeInformation -Encoding UTF8

    $index++
}

$summaryPath = Join-Path $outputFolder "summary.md"
$summary = New-Object System.Collections.Generic.List[string]
$summary.Add("# Manual color space capture summary")
$summary.Add("")
$summary.Add("Run: $runId")
$summary.Add("Monitor: $Monitor")
$summary.Add("")
$summary.Add("## Captured color spaces")
foreach ($capture in $captures) {
    $summary.Add("- $($capture.Index): $($capture.ColorSpace) -> $($capture.CsvPath)")
}
$summary.Add("")
$summary.Add("## Pairwise diffs")
if ($comparisons.Count -eq 0) {
    $summary.Add("- No pairwise comparisons were generated.")
}
else {
    foreach ($comparison in $comparisons) {
        $summary.Add("- $($comparison.From) -> $($comparison.To): $($comparison.Count) difference(s). See $($comparison.TextPath)")
    }
}
$summary.Add("")
$summary.Add("## Notes")
$summary.Add("This script does not write monitor values. It captures readable VCP values after manual OSD color-space changes.")
$summary | Set-Content -Path $summaryPath -Encoding UTF8

Write-Host ""
Write-Host "Manual color space capture finished." -ForegroundColor Green
Write-Host "Output folder:"
Write-Host "  $outputFolder"
Write-Host ""
Write-Host "Key files:"
Write-Host "  00_monitors.txt"
Write-Host "  observations.csv"
Write-Host "  summary.md"
Write-Host "  diff_*.txt / diff_*.csv"
Write-Host ""
Read-Host "Press Enter to close"
