param(
  [string]$ExePath = "$PSScriptRoot\LumiWrite.exe"
)

$progId = "LumiWrite.Markdown"

Remove-Item -Path "HKCU:\Software\Classes\.$('md')" -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\Classes\.$('markdown')" -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\Classes\$progId" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Done. File association removed for .md/.markdown."
