@echo off
setlocal

if "%_RUN_IN_WINDOW%"=="" (
  set _RUN_IN_WINDOW=1
  start "LumiWrite Release" cmd /k "%~f0 %*"
  exit /b
)

set VERSION=%1
set BUILD=%2
if "%VERSION%"=="" (
  echo No version provided.
  set /p VERSION=Enter version e.g. 0.2.0: 
)

if "%VERSION%"=="" (
  echo Version is required.
  pause
  exit /b 1
)

echo Releasing version %VERSION% ...
if /I "%BUILD%"=="--build" (
  powershell -ExecutionPolicy Bypass -File "%~dp0release_windows.ps1" -Version %VERSION% -Build true
) else (
  powershell -ExecutionPolicy Bypass -File "%~dp0release_windows.ps1" -Version %VERSION%
)
if errorlevel 1 (
  echo.
  echo Release failed with exit code %errorlevel%.
  pause
  exit /b %errorlevel%
)

echo.
echo Done.
pause
endlocal
