param(
  [string]$BuildDir = "$PSScriptRoot\..\build\windows\x64\runner\Release",
  [string]$OutDir = "$PSScriptRoot\..\dist",
  [string]$PackageName = "LumiWrite_Portable"
)

$buildPath = Resolve-Path -Path $BuildDir -ErrorAction SilentlyContinue
if (-not $buildPath) {
  Write-Host "Build directory not found: $BuildDir"
  Write-Host "Run: flutter build windows --release"
  exit 1
}

$outputPath = Join-Path $OutDir $PackageName
if (Test-Path $outputPath) {
  Remove-Item -Recurse -Force $outputPath
}
New-Item -ItemType Directory -Path $outputPath | Out-Null

Copy-Item -Path (Join-Path $buildPath '*') -Destination $outputPath -Recurse

Copy-Item -Path "$PSScriptRoot\register_md.ps1" -Destination $outputPath
Copy-Item -Path "$PSScriptRoot\unregister_md.ps1" -Destination $outputPath

$zipPath = Join-Path $OutDir "$PackageName.zip"
if (Test-Path $zipPath) {
  Remove-Item -Force $zipPath
}

Compress-Archive -Path $outputPath\* -DestinationPath $zipPath

Write-Host "Portable package created:"
Write-Host $zipPath
