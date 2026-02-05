@echo off
setlocal

powershell -ExecutionPolicy Bypass -File "%~dp0register_md.ps1" -Pause
endlocal
