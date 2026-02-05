param(
  [string]$ExePath = "$PSScriptRoot\LumiWrite.exe",
  [switch]$Pause
)

$ErrorActionPreference = "Stop"

function Finish-And-Exit([int]$code) {
  if ($Pause) {
    Write-Host ""
    Read-Host "Press Enter to exit"
  }
  exit $code
}

$progId = "LumiWrite.Markdown"

Remove-Item -Path "HKCU:\Software\Classes\.$('md')" -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\Classes\.$('markdown')" -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\Classes\$progId" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Done. File association removed for .md/.markdown."
Finish-And-Exit 0
