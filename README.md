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

There is also an unexpected observation: in the normal behavior of the red tint issue, the tint tended to reappear after a monitor power-off/power-on cycle. There did not appear to be a manual correction that survived a new monitor power cycle. After applying this DDC/CI reset, however, the corrected state may sometimes persist across several monitor power-off/power-on cycles, meaning the red tint does not necessarily return every time the monitor is turned off and on. This behavior has not been characterized yet. It should be treated as preliminary and requiring further testing.

## What this does

The main script sends this DDC/CI command to the target monitor:

```powershell
ControlMyMonitor.exe /SetValue <monitor> DC 0
```

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

## Diagnostic notes

The investigation found that:

- forcing `VCP 12 / Contrast = 50` did not fix the red tint;
- toggling `VCP 10 / Brightness` between the ECO and Normal brightness values did not fix it;
- the OSD preview/hover workaround corrected the image without exposing a persistent DDC/CI value difference;
- explicitly reapplying `VCP DC / Display Application = 0` corrected the red tint;
- unlike the earlier observed behavior, where the red tint tended to return after a monitor power cycle, the DDC/CI reset may sometimes survive several monitor off/on cycles.

See [`docs/diagnosis-summary.md`](docs/diagnosis-summary.md) for details. Spanish version: [`docs/diagnosis-summary.es.md`](docs/diagnosis-summary.es.md).

## Privacy note

This repository intentionally avoids user-specific filesystem paths such as Windows profile directories. Examples use relative paths or generic monitor identifiers.

## License

No license has been selected yet.
