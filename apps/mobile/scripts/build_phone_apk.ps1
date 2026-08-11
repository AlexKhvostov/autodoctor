# Builds a phone APK named: AutoDoctor-<versionName>+<buildNumber>.apk
# Example: AutoDoctor-0.1.0+1.apk
#
# Usage:
#   .\scripts\build_phone_apk.ps1
#   .\scripts\build_phone_apk.ps1 -ApiBaseUrl "http://192.168.50.81:8000/api/v1"
#   .\scripts\build_phone_apk.ps1 -BumpBuild
#
# Version comes from pubspec.yaml (version: x.y.z+build).
# -BumpBuild increments the +build number before compiling.

param(
    [string]$ApiBaseUrl = "",
    [string]$GoogleServerClientId = "592498720509-lrf8gtbkksq8q5ra1u7a8v14s6fnd1fm.apps.googleusercontent.com",
    [switch]$BumpBuild
)

$ErrorActionPreference = "Stop"
$mobileRoot = Split-Path -Parent $PSScriptRoot
Set-Location $mobileRoot

$pubspecPath = Join-Path $mobileRoot "pubspec.yaml"
$pubspec = Get-Content $pubspecPath -Raw
if ($pubspec -notmatch '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+(\d+)\s*$') {
    throw "Could not parse version from pubspec.yaml"
}
$versionName = $Matches[1]
$buildNumber = [int]$Matches[2]

if ($BumpBuild) {
    $buildNumber++
    $pubspec = [regex]::Replace(
        $pubspec,
        '(?m)^version:\s*[0-9]+\.[0-9]+\.[0-9]+\+\d+\s*$',
        "version: $versionName+$buildNumber"
    )
    Set-Content -Path $pubspecPath -Value $pubspec -NoNewline
    Write-Host "Bumped build number to $versionName+$buildNumber"
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $lanIp = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } |
        Select-Object -First 1 -ExpandProperty IPAddress)
    if (-not $lanIp) {
        throw "No LAN IP found. Pass -ApiBaseUrl explicitly."
    }
    $ApiBaseUrl = "http://${lanIp}:8000/api/v1"
}

$artifactName = "AutoDoctor-$versionName+$buildNumber.apk"
$outDir = Join-Path $mobileRoot "build\phone"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir $artifactName

Write-Host "Building $artifactName"
Write-Host "API_BASE_URL=$ApiBaseUrl"

flutter build apk --release `
    --build-name=$versionName `
    --build-number=$buildNumber `
    --dart-define="API_BASE_URL=$ApiBaseUrl" `
    --dart-define="GOOGLE_SERVER_CLIENT_ID=$GoogleServerClientId"

$built = Join-Path $mobileRoot "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $built)) {
    throw "APK not found: $built"
}

Copy-Item -Path $built -Destination $outPath -Force
Write-Host ""
Write-Host "Ready: $outPath"
Write-Host "Install on phone, keep API running: php artisan serve --host=0.0.0.0 --port=8000"
