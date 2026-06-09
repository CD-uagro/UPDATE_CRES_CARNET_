param(
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"

function Fail {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Fail "No se encontro: $Path"
    }
    return Get-Content $Path -Raw | ConvertFrom-Json
}

function Read-TextFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Fail "No se encontro: $Path"
    }
    return [System.IO.File]::ReadAllText($Path)
}

function Write-TextFile {
    param([string]$Path, [string]$Content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$versionPath = Join-Path $repoRoot "version.json"
$assetsVersionPath = Join-Path $repoRoot "assets\version.json"
$pubspecPath = Join-Path $repoRoot "pubspec.yaml"
$setupPath = Join-Path $repoRoot "installer\setup_script.iss"

$versionInfo = Read-JsonFile $versionPath
$version = [string]$versionInfo.version
$buildNumber = [int]$versionInfo.buildNumber

if ([string]::IsNullOrWhiteSpace($version)) {
    Fail "version.json no contiene 'version'."
}

if ($buildNumber -le 0) {
    Fail "version.json debe contener buildNumber mayor a 0."
}

$pubspecVersionLine = "version: $version+$buildNumber"
$setupVersionLine = "#define MyAppVersion `"$version`""

if (-not $CheckOnly) {
    if (-not (Test-Path (Split-Path -Parent $assetsVersionPath))) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $assetsVersionPath) -Force | Out-Null
    }

    Copy-Item -Path $versionPath -Destination $assetsVersionPath -Force

    if (-not (Test-Path $pubspecPath)) {
        Fail "No se encontro: $pubspecPath"
    }
    $pubspecContent = Read-TextFile $pubspecPath
    $pubspecLines = $pubspecContent -split "\r?\n", -1
    $pubspecVersionIndex = -1
    for ($i = 0; $i -lt $pubspecLines.Count; $i++) {
        if ($pubspecLines[$i].TrimStart().StartsWith("version:")) {
            $pubspecVersionIndex = $i
            break
        }
    }
    if ($pubspecVersionIndex -lt 0) {
        Fail "pubspec.yaml no contiene una linea 'version:' para sincronizar."
    }
    $pubspecLines[$pubspecVersionIndex] = $pubspecVersionLine
    Write-TextFile $pubspecPath ($pubspecLines -join "`r`n")

    if (-not (Test-Path $setupPath)) {
        Fail "No se encontro: $setupPath"
    }
    $setupContent = Read-TextFile $setupPath
    $setupLines = $setupContent -split "\r?\n", -1
    $setupVersionIndex = -1
    for ($i = 0; $i -lt $setupLines.Count; $i++) {
        if ($setupLines[$i].TrimStart().StartsWith("#define MyAppVersion")) {
            $setupVersionIndex = $i
            break
        }
    }
    if ($setupVersionIndex -lt 0) {
        Fail "setup_script.iss no contiene '#define MyAppVersion'."
    }
    $setupLines[$setupVersionIndex] = $setupVersionLine
    Write-TextFile $setupPath ($setupLines -join "`r`n")
}

$assetsInfo = Read-JsonFile $assetsVersionPath
if ([string]$assetsInfo.version -ne $version) {
    Fail "assets/version.json version='$($assetsInfo.version)' no coincide con version.json version='$version'."
}
if ([int]$assetsInfo.buildNumber -ne $buildNumber) {
    Fail "assets/version.json buildNumber='$($assetsInfo.buildNumber)' no coincide con version.json buildNumber='$buildNumber'."
}

$pubspecAfter = Read-TextFile $pubspecPath
$pubspecAfterLines = $pubspecAfter -split "\r?\n"
if (-not ($pubspecAfterLines -contains $pubspecVersionLine)) {
    Fail "pubspec.yaml no contiene '$pubspecVersionLine'."
}

$setupAfter = Read-TextFile $setupPath
$setupAfterLines = $setupAfter -split "\r?\n"
if (-not ($setupAfterLines -contains $setupVersionLine)) {
    Fail "setup_script.iss no contiene '$setupVersionLine'."
}

Write-Host "Version sync OK" -ForegroundColor Green
Write-Host "  version.json:          $version / build $buildNumber"
Write-Host "  assets/version.json:   $($assetsInfo.version) / build $($assetsInfo.buildNumber)"
Write-Host "  pubspec.yaml:          $pubspecVersionLine"
Write-Host "  setup_script.iss:      $setupVersionLine"
