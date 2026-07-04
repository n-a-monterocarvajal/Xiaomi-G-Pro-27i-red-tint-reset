# Xiaomi G Pro 27i Red Tint Reset

Small Windows script to mitigate the documented red tint issue on the **Xiaomi Mini LED Gaming Monitor G Pro 27i** by reapplying a DDC/CI display application value.

Spanish version: [`README.es.md`](README.es.md).

The confirmed workaround in this case is:

```text
VCP DC / Display Application = 0
```

This reproduces the corrective effect observed when opening the monitor OSD, hovering over another picture profile such as ECO, and returning to Normal.

## Important scope note

This was tested in a very specific environment:

- one Xiaomi Mini LED Gaming Monitor G Pro 27i unit;
- used as an external monitor connected to a laptop;
- set as the Windows primary display;
- HDR off;
- FreeSync off;
- local dimming off;
- tested at 60 Hz;
- Windows with DDC/CI access through ControlMyMonitor.

No exhaustive testing has been performed with HDR on, FreeSync on, local dimming on, different refresh rates, different GPU drivers, different cables, different connection setups, desktop PCs, or additional units of the same monitor.

There is also an unexpected observation: in the normal behavior of the red tint issue, the tint tended to reappear after a monitor power-off/power-on cycle. There did not appear to be a manual correction that survived a new monitor power cycle. After applying this DDC/CI reset, however, the corrected state may sometimes persist across several monitor power-off/power-on cycles, meaning the red tint does not necessarily return every time the monitor is turned off and on.

A related preliminary observation is that the corrected state also appears to survive at least some standby/resume cycles. For example, if the computer is turned off or stops sending signal and the monitor enters standby by signal timeout, the image may still remain corrected when signal returns after the computer is turned on again. This behavior has not been characterized yet. It should be treated as preliminary and requiring further testing.

## Color space observation

A later observation suggests that `VCP DC = 0` is related to the monitor's internal picture/color pipeline, not only to an invisible red tint reset.

On the tested unit, when the monitor OSD color space was set to **DCI-P3**, running the reset script returned the monitor to **Native** color space. This makes it plausible that the red tint issue is connected to a stale or incorrectly applied color-space/gamut state, and that reapplying `VCP DC = 0` forces the monitor firmware to reload or reset that part of the image processing path.

A read-only manual color-space capture was later performed by changing only the OSD color space step by step: Native, Adobe RGB, DCI-P3 and sRGB. In the VCP values common to all four captures, the only stable value change was:

```text
VCP 0C / Color Temperature Request
Native   = 1
Adobe RGB = 2
DCI-P3   = 2
sRGB     = 2
```

During that same manual test, `VCP DC / Display Application` remained `0`, and `VCP 14 / Select Color Preset` remained `5` across all four OSD color spaces. Brightness, input source and power mode also remained stable.

This suggests that the detailed OSD color-space choices are not exposed as one clean standard VCP value through ControlMyMonitor. Native leaves a visible trace through `VCP 0C = 1`, while Adobe RGB, DCI-P3 and sRGB share `VCP 0C = 2`; the finer distinction between those non-Native modes may be handled internally by the monitor firmware or through manufacturer-specific state.

A subjective visual note from the same investigation: on a white background, changing the OSD color space may make the red tint appear again, while the manual OSD workaround appears to correct the tint while preserving the selected color space as reported by the OSD. This is still an observation, not a controlled measurement.

## What this does

The main script sends this DDC/CI command to the target monitor:

```powershell
ControlMyMonitor.exe /SetValue <monitor> DC 0
```

Observed side effect on the tested unit:

- it may reset the monitor OSD color space/gamut setting to **Native**.

It does **not** change:

- input source;
- power mode;
- brightness;
- contrast;
- Windows color profile;
- GPU settings.

## Requirements

- Windows.
- [ControlMyMonitor](https://www.nirsoft.net/utils/control_my_monitor.html) by NirSoft.
- The Xiaomi monitor must be reachable over DDC/CI.

No DDC/CI on/off toggle was found in the tested monitor OSD. In this setup, DDC/CI appears to be the monitor's default behavior rather than a user-facing OSD option.

## Quick start

Place `ControlMyMonitor.exe` in the same folder as the PowerShell script, or pass its path with `-ControlMyMonitor`.

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Reset-Xiaomi-RedTint.ps1" -Monitor "Primary"
```

If the Xiaomi monitor is not the Windows primary display, first identify its monitor string:

```powershell
.\ControlMyMonitor.exe /smonitors ".\monitors.txt"
notepad ".\monitors.txt"
```

Then run the reset with the detected monitor string, for example:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Reset-Xiaomi-RedTint.ps1" -Monitor "\\.\DISPLAY2\Monitor0"
```

## Double-click BAT launcher

A simple launcher is included at:

```text
scripts\Reset-Xiaomi-RedTint.bat
```

Edit the `MONITOR_ID` variable in that file if needed.

## Read-only color-space capture script

A tested read-only helper script is included at:

```text
scripts\Capture-Manual-ColorSpace-Changes-WAIT.ps1
```

It does not write monitor values. It guides the user through manual OSD color-space changes and captures all readable VCP values after each step.

Example:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Capture-Manual-ColorSpace-Changes-WAIT.ps1" -Monitor "Primary"
```

## Diagnostic notes

The investigation found that:

- forcing `VCP 12 / Contrast = 50` did not fix the red tint;
- toggling `VCP 10 / Brightness` between the ECO and Normal brightness values did not fix it;
- the OSD preview/hover workaround corrected the image without exposing a persistent DDC/CI value difference;
- explicitly reapplying `VCP DC / Display Application = 0` corrected the red tint;
- when the OSD color space was set to DCI-P3, applying `VCP DC = 0` returned it to Native;
- manual OSD color-space changes did not change `VCP DC`, which stayed at `0`;
- the only stable common VCP value change across Native, Adobe RGB, DCI-P3 and sRGB was `VCP 0C`: Native = `1`, non-Native modes = `2`;
- unlike the earlier observed behavior, where the red tint tended to return after a monitor power cycle, the DDC/CI reset may sometimes survive several monitor off/on cycles;
- the corrected state may also survive some standby/resume cycles triggered by signal timeout.

See [`docs/diagnosis-summary.md`](docs/diagnosis-summary.md) for details. Spanish version: [`docs/diagnosis-summary.es.md`](docs/diagnosis-summary.es.md).

## Privacy note

This repository intentionally avoids user-specific filesystem paths such as Windows profile directories. Examples use relative paths or generic monitor identifiers.

## License

No license has been selected yet.
