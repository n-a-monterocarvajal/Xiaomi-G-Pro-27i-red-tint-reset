@echo off
setlocal

REM Edit this if your Xiaomi monitor is not the Windows primary monitor.
REM Example: set "MONITOR_ID=\\.\DISPLAY2\Monitor0"
set "MONITOR_ID=Primary"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Reset-Xiaomi-RedTint.ps1" -Monitor "%MONITOR_ID%"

endlocal
