param(
    [string]$Godot = "godot"
)

$ErrorActionPreference = "Stop"
$Project = Split-Path -Parent $PSScriptRoot
$BuildRoot = Join-Path $Project "builds"

New-Item -ItemType Directory -Force -Path (Join-Path $BuildRoot "web") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $BuildRoot "windows") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $BuildRoot "android") | Out-Null

& $Godot --headless --path $Project --import
if ($LASTEXITCODE -ne 0) { throw "Godot import failed" }

& $Godot --headless --path $Project --script (Join-Path $Project "tests/run_tests.gd")
if ($LASTEXITCODE -ne 0) { throw "Tests failed" }

& $Godot --headless --path $Project --script (Join-Path $Project "tools/static_validate.gd")
if ($LASTEXITCODE -ne 0) { throw "Static validation failed" }

& $Godot --headless --path $Project --export-release "Web" (Join-Path $BuildRoot "web/index.html")
if ($LASTEXITCODE -ne 0) { throw "Web export failed" }

& $Godot --headless --path $Project --export-release "Windows" (Join-Path $BuildRoot "windows/THE_FIRST_NIGHT.exe")
if ($LASTEXITCODE -ne 0) { throw "Windows export failed" }

& $Godot --headless --path $Project --export-debug "Android" (Join-Path $BuildRoot "android/the-first-night-debug.apk")
if ($LASTEXITCODE -ne 0) { throw "Android export failed" }

Compress-Archive -Force -Path (Join-Path $BuildRoot "windows/*") -DestinationPath (Join-Path $BuildRoot "THE_FIRST_NIGHT-windows.zip")
Get-FileHash -Algorithm SHA256 (Join-Path $BuildRoot "THE_FIRST_NIGHT-windows.zip"), (Join-Path $BuildRoot "android/the-first-night-debug.apk") |
    ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path -Leaf $_.Path)" } |
    Set-Content -Encoding utf8 (Join-Path $BuildRoot "SHA256SUMS.txt")

Write-Host "All verification and exports completed: $BuildRoot"

