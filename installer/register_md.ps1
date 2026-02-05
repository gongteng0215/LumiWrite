param(
  [string]$ExePath = "$PSScriptRoot\LumiWrite.exe"
)

if (-not (Test-Path $ExePath)) {
  Write-Host "Exe not found: $ExePath"
  exit 1
}

$progId = "LumiWrite.Markdown"
$openCmd = "`"$ExePath`" `"%1`""

New-Item -Path "HKCU:\Software\Classes\.md" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\.md" -Name "(Default)" -Value $progId

New-Item -Path "HKCU:\Software\Classes\.markdown" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\.markdown" -Name "(Default)" -Value $progId

New-Item -Path "HKCU:\Software\Classes\$progId\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\$progId\DefaultIcon" -Name "(Default)" -Value "`"$ExePath`",0"

New-Item -Path "HKCU:\Software\Classes\$progId\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\$progId\shell\open\command" -Name "(Default)" -Value $openCmd

Write-Host "Done. File association set for .md/.markdown."
