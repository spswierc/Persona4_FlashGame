@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve_nozoki.ps1"
if errorlevel 1 (
  echo.
  echo Could not start Nozoki. See README.txt.
  pause
)
