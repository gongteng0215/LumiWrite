@echo off
setlocal

powershell -ExecutionPolicy Bypass -File "%~dp0unregister_md.ps1" -Pause
endlocal
