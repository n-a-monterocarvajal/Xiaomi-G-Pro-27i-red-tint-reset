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

## Color space / gamut observation

A later observation suggests that the successful command is linked to the monitor's internal picture/color pipeline.

When the monitor OSD color space was set to **DCI-P3**, applying:

```powershell
ControlMyMonitor.exe /SetValue <monitor> DC 0
```

returned the monitor to **Native** color space.

This suggests that `VCP DC = 0` may be more than a narrow red tint reset. It may force the monitor firmware to reload or reset the active display application, including the color-space/gamut state. A possible hypothesis is that the red tint issue is related to a stale, corrupted, or incorrectly applied internal color-space/gamut state.

## Manual color-space capture

A later read-only capture tested manual OSD color-space changes without writing any VCP values. The sequence was:

1. Native.
2. Adobe RGB.
3. DCI-P3.
4. sRGB.

All four states were captured with ControlMyMonitor after changing only the OSD color-space setting.

Among the VCP codes present in all four captures, only one stable value changed:

```text
VCP 0C / Color Temperature Request
Native    = 1
Adobe RGB = 2
DCI-P3    = 2
sRGB      = 2
```

Relevant values that did not change across the four captured OSD color spaces:

```text
VCP DC / Display Application = 0
VCP 14 / Select Color Preset = 5
VCP 10 / Brightness = 20
VCP 60 / Input Select = 15
VCP D6 / Power Mode = 1
```

The pairwise diffs also showed several presence/absence differences between captures. Those are documented as lower-confidence because DDC/CI reads can be inconsistent and some controls may appear or disappear between reads. The most reliable finding is the comparison of VCP codes common to all four captures.

Interpretation: the OSD color-space selector is not exposed as one clean standard VCP value. Native leaves a visible trace as `VCP 0C = 1`, while Adobe RGB, DCI-P3 and sRGB all report `VCP 0C = 2`. The fine distinction between Adobe RGB, DCI-P3 and sRGB may be stored in firmware state or in a manufacturer-specific control not exposed by ControlMyMonitor.

Subjective visual note: the red tint can be difficult to judge, and changes are easier to see on a white background. The user observed that changing the OSD color space may make the red tint appear again. The manual OSD workaround —hover ECO without selecting it, then hover Standard/Normal and select it— appears to correct the tint while preserving the selected OSD color space, at least according to the OSD.

## Tools used

- Windows PowerShell.
- NirSoft ControlMyMonitor.
- DDC/CI VCP reads and writes.
- `scripts/Capture-Manual-ColorSpace-Changes-WAIT.ps1` for read-only manual color-space capture.

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

A later check found that this same command can reset the monitor OSD color space from DCI-P3 to Native on the tested unit. This means users who intentionally work in DCI-P3 may need to re-check the OSD color-space setting after running the script.

However, manual OSD changes between Native, Adobe RGB, DCI-P3 and sRGB did not change `VCP DC`, which remained `0`. Therefore, `VCP DC = 0` should not be described as the direct color-space selector. It is more likely a broader display-application reset or reload that can indirectly return the monitor to Native.

## Final recommendation

Use only:

```text
VCP DC = 0
```

Avoid automating input source, power mode, or other manufacturer-specific values unless additional testing proves they are safe.

If color-space accuracy matters, re-check the OSD color-space setting after running the reset, because the reset may return the monitor to Native.

## Open questions

- Does the workaround still work with HDR enabled?
- Does the workaround still work with FreeSync enabled?
- Does the workaround still work with local dimming enabled?
- Does the workaround behave the same at refresh rates above 60 Hz?
- Does the workaround behave the same when the monitor is not connected to a laptop or is not set as the primary Windows display?
- Why does the corrected state sometimes persist across several monitor power cycles after applying the DDC/CI command, when the earlier/manual correction appeared not to survive a fresh monitor power-on?
- Why does the corrected state sometimes survive standby/resume cycles triggered by signal timeout?
- Why does `VCP DC = 0` return DCI-P3 to Native if manual OSD color-space changes do not change `VCP DC`?
- Where does the monitor store the fine distinction between Adobe RGB, DCI-P3 and sRGB if all three report `VCP 0C = 2`?
- Is the red tint issue caused by a stale or incorrectly applied internal color-space/gamut state?
- Is the persistence controlled by monitor firmware state, OSD state, DDC/CI state, signal loss/recovery behavior, color-space state, or Windows/GPU behavior?
