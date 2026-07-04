# Diagnosis summary

Spanish version: [`diagnosis-summary.es.md`](diagnosis-summary.es.md).

This document summarizes the investigation performed on the Xiaomi Mini LED Gaming Monitor G Pro 27i red tint issue.

## Context

The monitor may show a red tint after some state changes. A known manual workaround is to open the monitor OSD, move from the desired profile such as Normal to another profile such as ECO, and then return to Normal.

The goal was to discover whether that corrective effect could be reproduced through DDC/CI.

## Test environment and limitations

This result was obtained in a very specific setup:

- one Xiaomi Mini LED Gaming Monitor G Pro 27i unit;
- used as an external monitor connected to a laptop;
- set as the Windows primary display;
- HDR disabled;
- FreeSync disabled;
- local dimming disabled;
- 60 Hz refresh rate;
- Windows with ControlMyMonitor used for DDC/CI commands.

The following cases have not been exhaustively tested:

- HDR enabled;
- FreeSync enabled;
- local dimming enabled;
- refresh rates other than 60 Hz;
- different cables or ports;
- different connection setups;
- desktop PCs;
- different GPUs or GPU drivers;
- additional units of the same monitor.

Therefore, this should be treated as a working finding for one observed environment, not as a fully generalized fix for all possible configurations.

## DDC/CI availability note

No DDC/CI on/off toggle was found in the tested monitor OSD. In this setup, DDC/CI appears to be the monitor's default behavior rather than a user-facing OSD option.

The actual requirement is that the Xiaomi monitor must be reachable over DDC/CI from Windows and ControlMyMonitor.

## Unexpected persistence observation

One unexpected behavior was observed after applying the DDC/CI reset.

Before this DDC/CI workaround, the red tint tended to reappear after a monitor power-off/power-on cycle. In other words, the manual OSD workaround did not appear to produce a correction that survived a new monitor power cycle; the red tint would normally be present again on a fresh monitor power-on.

After applying the DDC/CI reset, however, the corrected state may sometimes remain active across several monitor power-off/power-on cycles. This means the red tint does not necessarily return every time the monitor is turned off and on after the DDC/CI command has been applied.

A related preliminary observation is that the corrected state also appears to survive at least some standby/resume cycles. For example, when the computer is turned off or stops sending signal and the monitor enters standby after a signal timeout, the image may still remain corrected when signal returns after the computer is turned on again.

This persistence is not yet understood. It may depend on monitor firmware state, OSD state, DDC/CI state caching, signal loss/recovery behavior, power state, or another internal condition. It needs further controlled testing.

At this stage, it should be documented only as a preliminary observation, not as guaranteed behavior.

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

## Open questions

- Does the workaround still work with HDR enabled?
- Does the workaround still work with FreeSync enabled?
- Does the workaround still work with local dimming enabled?
- Does the workaround behave the same at refresh rates above 60 Hz?
- Does the workaround behave the same when the monitor is not connected to a laptop or is not set as the primary Windows display?
- Why does the corrected state sometimes persist across several monitor power cycles after applying the DDC/CI command, when the earlier/manual correction appeared not to survive a fresh monitor power-on?
- Why does the corrected state sometimes survive standby/resume cycles triggered by signal timeout?
- Is the persistence controlled by monitor firmware state, OSD state, DDC/CI state, signal loss/recovery behavior, or Windows/GPU behavior?
