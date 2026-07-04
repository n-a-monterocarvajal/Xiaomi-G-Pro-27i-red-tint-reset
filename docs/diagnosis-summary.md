# Diagnosis summary

This document summarizes the investigation performed on the Xiaomi Mini LED Gaming Monitor G Pro 27i red tint issue.

## Context

The monitor may show a red tint after some state changes. A known manual workaround is to open the monitor OSD, move from the desired profile such as Normal to another profile such as ECO, and then return to Normal.

The goal was to discover whether that corrective effect could be reproduced through DDC/CI.

## Tools used

- Windows PowerShell.
- NirSoft ControlMyMonitor.
- DDC/CI VCP reads and writes.

## Diagnostic sequence

### 1. Capture states before and after profile changes

Three states were captured:

1. Normal with red tint visible.
2. ECO selected or previewed in the OSD.
3. Normal again after the red tint was corrected.

### 2. Discarded candidates

#### VCP 12 / Contrast

One early diff showed contrast moving from `0` to `50`, but explicitly applying:

```powershell
ControlMyMonitor.exe /SetValue <monitor> 12 50
```

did not correct the red tint.

Conclusion: this value was likely a read artifact or a secondary state, not the cause of the correction.

#### VCP 10 / Brightness

A cleaner Normal to ECO to Normal test showed brightness changing:

```text
Normal -> ECO: 32 -> 20
ECO -> Normal: 20 -> 32
```

However, explicitly toggling brightness:

```text
20 -> 32
```

did not correct the red tint.

Conclusion: brightness changes were real but not sufficient to trigger the internal correction.

#### VCP 60 / Input Select and VCP D6 / Power Mode

These appeared in an early capture, but they were not used for automation because they are riskier:

- `60` can change the input source.
- `D6` can affect the monitor power state.

They are intentionally not used by the final script.

## Successful candidate

The successful command was:

```powershell
ControlMyMonitor.exe /SetValue <monitor> DC 0
```

This reapplies:

```text
VCP DC / Display Application = 0
```

It corrected the red tint without changing brightness, input source, power mode, or contrast.

## Final recommendation

Use only:

```text
VCP DC = 0
```

Avoid automating input source, power mode, or other manufacturer-specific values unless additional testing proves they are safe.
