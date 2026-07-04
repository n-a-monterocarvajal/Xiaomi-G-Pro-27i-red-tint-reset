@echo off
setlocal

set "CMM=%~dp0ControlMyMonitor.exe"
set "OUT=%~dp0monitors.txt"

if not exist "%CMM%" (
  echo ControlMyMonitor.exe was not found next to this script.
  echo Copy ControlMyMonitor.exe into the scripts folder or edit this BAT file.
  pause
  exit /b 1
)

"%CMM%" /smonitors "%OUT%"
notepad "%OUT%"

endlocal
