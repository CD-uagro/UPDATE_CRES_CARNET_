param(
    [Parameter(Mandatory = $true)]
    [string]$MultitenantApiBaseUrl
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($MultitenantApiBaseUrl)) {
    throw "MULTITENANT_API_BASE_URL es obligatorio."
}

if (-not ($MultitenantApiBaseUrl.StartsWith("https://"))) {
    throw "La URL staging debe usar HTTPS."
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$releaseRoot = Join-Path $repoRoot "releases\multitenant\SaludDigitalInstitucional"
$sourceRelease = Join-Path $repoRoot "build\windows\x64\runner\Release"
$sourceExe = Join-Path $sourceRelease "cres_carnets_ibmcloud.exe"
$targetExe = Join-Path $releaseRoot "SaludDigitalInstitucional.exe"
$manifestPath = Join-Path $releaseRoot "build_manifest.json"

Write-Host "SASU MULTITENANT - Build Windows" -ForegroundColor Cyan
Write-Host "API staging: $MultitenantApiBaseUrl" -ForegroundColor Gray

flutter build windows --release `
    --dart-define=APP_VARIANT=MULTITENANT `
    --dart-define=MULTITENANT_API_BASE_URL=$MultitenantApiBaseUrl

if (Test-Path -LiteralPath $releaseRoot) {
    Remove-Item -LiteralPath $releaseRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $releaseRoot | Out-Null

Get-ChildItem -LiteralPath $sourceRelease -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $releaseRoot -Recurse -Force
}
Move-Item -LiteralPath (Join-Path $releaseRoot "cres_carnets_ibmcloud.exe") -Destination $targetExe -Force

$files = Get-ChildItem -LiteralPath $releaseRoot -Recurse -File | ForEach-Object {
    [PSCustomObject]@{
        path = $_.FullName.Substring($releaseRoot.Length + 1)
        bytes = $_.Length
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
}

$manifest = [PSCustomObject]@{
    app_variant = "MULTITENANT"
    api_base_url = $MultitenantApiBaseUrl
    executable = "SaludDigitalInstitucional.exe"
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    files = $files
}

$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Host "Build MULTITENANT listo:" -ForegroundColor Green
Write-Host "  Carpeta: $releaseRoot"
Write-Host "  Ejecutable: $targetExe"
Write-Host "  Manifest: $manifestPath"
