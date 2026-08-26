# Builds a phone APK named: AutoDoctor-<versionName>+<buildNumber>.apk
# Example: AutoDoctor-0.1.0+1.apk
#
# Usage:
#   .\scripts\build_phone_apk.ps1
#   .\scripts\build_phone_apk.ps1 -ApiBaseUrl "http://192.168.50.81:8000/api/v1"
#   .\scripts\build_phone_apk.ps1 -UseRemoteConfig
#   .\scripts\build_phone_apk.ps1 -BumpBuild
#
#   .\scripts\build_phone_apk.ps1 -HideDevMenu
#
# -UseRemoteConfig omits API_BASE_URL so the app follows Firebase Remote Config
# (key api_base_url). Manual pick in Settings still overrides RC.
# -HideDevMenu hides the "Development" item in More (API switch, UI kit).
#
# Version comes from pubspec.yaml (version: x.y.z+build).
# -BumpBuild increments the +build number before compiling.

param(
    [string]$ApiBaseUrl = "",
    [string]$GoogleServerClientId = "592498720509-lrf8gtbkksq8q5ra1u7a8v14s6fnd1fm.apps.googleusercontent.com",
    [switch]$UseRemoteConfig,
    [switch]$BumpBuild,
    [switch]$HideDevMenu
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

$defines = @(
    "--dart-define=GOOGLE_SERVER_CLIENT_ID=$GoogleServerClientId"
)

if ($UseRemoteConfig) {
    Write-Host "API: Firebase Remote Config (api_base_url)"
} else {
    if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
        $lanIp = (Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } |
            Select-Object -First 1 -ExpandProperty IPAddress)
        if (-not $lanIp) {
            throw "No LAN IP found. Pass -ApiBaseUrl or -UseRemoteConfig."
        }
        $ApiBaseUrl = "http://${lanIp}:8000/api/v1"
    }
    Write-Host "API_BASE_URL=$ApiBaseUrl"
    $defines += "--dart-define=API_BASE_URL=$ApiBaseUrl"
}

if ($HideDevMenu) {
    Write-Host "SHOW_DEV_MENU=false"
    $defines += "--dart-define=SHOW_DEV_MENU=false"
}

$artifactName = "AutoDoctor-$versionName+$buildNumber.apk"
$outDir = Join-Path $mobileRoot "build\phone"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir $artifactName

Write-Host "Building $artifactName"

$flutterArgs = @(
    "build", "apk", "--release",
    "--build-name=$versionName",
    "--build-number=$buildNumber"
) + $defines
& flutter @flutterArgs
if ($LASTEXITCODE -ne 0) {
    throw "flutter build apk failed with exit code $LASTEXITCODE"
}

$built = Join-Path $mobileRoot "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $built)) {
    throw "APK not found: $built"
}

Copy-Item -Path $built -Destination $outPath -Force
Write-Host ""
Write-Host "Ready: $outPath"
if ($UseRemoteConfig) {
    Write-Host "Install on phone. API comes from Firebase Remote Config (api_base_url)."
} else {
    Write-Host "Install on phone, keep API running: php artisan serve --host=0.0.0.0 --port=8000"
}
