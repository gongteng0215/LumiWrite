param(
  [Parameter(Mandatory = $true)]
  [string]$Version,
  [string]$Notes = "",
  [string]$Build = "false"
)

$ErrorActionPreference = "Stop"

function Finish-And-Exit([int]$code) {
  exit $code
}

$pubspecPath = Join-Path $PSScriptRoot "..\pubspec.yaml"
if (Test-Path $pubspecPath) {
  $pubspecLines = Get-Content -Path $pubspecPath
  $currentVersion = ""
  foreach ($line in $pubspecLines) {
    if ($line -match "^\s*version:\s*(.+)$") {
      $currentVersion = $Matches[1].Trim()
      break
    }
  }

  $build = "1"
  if ($currentVersion -match "\+(\d+)$") {
    $build = $Matches[1]
  }

  $newVersion = $Version
  if (-not ($Version -match "\+")) {
    $newVersion = "$Version+$build"
  }

  $pubspecLines = $pubspecLines | ForEach-Object {
    if ($_ -match "^\s*version:\s*") {
      "version: $newVersion"
    } else {
      $_
    }
  }

  Set-Content -Path $pubspecPath -Value $pubspecLines
  Write-Host "Updated pubspec.yaml version to $newVersion"
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
  Write-Host "GitHub CLI (gh) not found. Install it first, then run again."
  Finish-And-Exit 1
}

$doBuild = $Build -match "^(1|true|yes|y)$"
if ($doBuild) {
  Write-Host "Running: flutter build windows --release"
  & flutter build windows --release
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build failed with exit code $LASTEXITCODE"
    Finish-And-Exit $LASTEXITCODE
  }
}

$tag = $Version
if (-not $tag.StartsWith("v")) {
  $tag = "v$Version"
}

$distDir = Resolve-Path -Path "$PSScriptRoot\..\dist" -ErrorAction SilentlyContinue
if (-not $distDir) {
  New-Item -ItemType Directory -Path "$PSScriptRoot\..\dist" | Out-Null
  $distDir = Resolve-Path -Path "$PSScriptRoot\..\dist"
}

$portableZip = Join-Path $distDir "LumiWrite_Portable.zip"
Write-Host "Repackaging portable zip..."
& "$PSScriptRoot\package_portable.ps1"
if ($LASTEXITCODE -ne 0) {
  Write-Host "Packaging failed with exit code $LASTEXITCODE"
  Finish-And-Exit $LASTEXITCODE
}

if (-not (Test-Path $portableZip)) {
  Write-Host "Portable zip not found after packaging: $portableZip"
  Finish-And-Exit 1
}

$windowsZip = Join-Path $distDir "LumiWrite_Windows_$tag.zip"
Copy-Item -Path $portableZip -Destination $windowsZip -Force

$title = "LumiWrite $tag (Windows)"
$releaseDate = Get-Date -Format "yyyy-MM-dd"

$prevTag = ""
try {
  $tags = & git tag --sort=-version:refname
  foreach ($t in $tags) {
    if ($t -ne $tag) {
      $prevTag = $t
      break
    }
  }
} catch {
  $prevTag = ""
}

$logLines = @()
try {
  if ($prevTag -ne "") {
    $logLines = & git log "$prevTag..HEAD" --pretty=format:"- %s"
  } else {
    $logLines = & git log -n 20 --pretty=format:"- %s"
  }
} catch {
  $logLines = @()
}

if ($logLines.Count -eq 0) {
  $logLines = @("- General improvements")
}

$notesLines = @(
  "## LumiWrite $tag (Windows)",
  "",
  "Release date: $releaseDate",
  ""
)

if ($Notes -ne "") {
  $notesLines += "Notes: $Notes"
  $notesLines += ""
}

$notesLines += "Changes:"
$notesLines += $logLines
$notesLines += ""
$notesLines += "OS: Windows"

$notesFile = Join-Path $distDir "release_notes_$tag.txt"
Set-Content -Path $notesFile -Value $notesLines

& gh release create $tag $windowsZip --title $title --notes-file $notesFile

Write-Host "Release created: $title"
Finish-And-Exit 0
