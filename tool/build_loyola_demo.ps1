param(
    [string]$LoyolaApiBaseUrl = "",
    [string]$OutputDir = "releases\loyola_demo"
)

$ErrorActionPreference = "Stop"

function Stop-Build($Message) {
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

Write-Host "SASU LOYOLA DEMO - Build Windows" -ForegroundColor Cyan
Write-Host "Variante: LOYOLA_DEMO" -ForegroundColor Gray

if (-not (Test-Path "pubspec.yaml")) {
    Stop-Build "Ejecuta este script desde la raiz del proyecto."
}

$buildArgs = @(
    "build",
    "windows",
    "--release",
    "--dart-define=APP_VARIANT=LOYOLA_DEMO"
)

if ($LoyolaApiBaseUrl.Trim().Length -gt 0) {
    $buildArgs += "--dart-define=LOYOLA_API_BASE_URL=$LoyolaApiBaseUrl"
    Write-Host "Backend demo: configurado por dart-define" -ForegroundColor Green
} else {
    Write-Host "Backend demo: no configurado; se usara modo local de demostracion" -ForegroundColor Yellow
}

Write-Host "Ejecutando flutter build windows..." -ForegroundColor Yellow
& flutter @buildArgs
if ($LASTEXITCODE -ne 0) {
    Stop-Build "flutter build windows fallo."
}

$sourceDir = "build\windows\x64\runner\Release"
$sourceExe = Join-Path $sourceDir "cres_carnets_ibmcloud.exe"
if (-not (Test-Path $sourceExe)) {
    Stop-Build "No se encontro el ejecutable generado: $sourceExe"
}

$targetDir = Join-Path $OutputDir "SASU_LOYOLA_Demo"
if (Test-Path $targetDir) {
    Write-Host "Limpiando solo artefacto demo previo: $targetDir" -ForegroundColor Yellow
    Remove-Item -LiteralPath $targetDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
Copy-Item -Path (Join-Path $sourceDir "*") -Destination $targetDir -Recurse -Force

$targetOriginalExe = Join-Path $targetDir "cres_carnets_ibmcloud.exe"
$targetDemoExe = Join-Path $targetDir "SASU_LOYOLA_Demo.exe"
Rename-Item -LiteralPath $targetOriginalExe -NewName "SASU_LOYOLA_Demo.exe"

Write-Host "Build LOYOLA listo:" -ForegroundColor Green
Write-Host "  Carpeta: $targetDir" -ForegroundColor Cyan
Write-Host "  Ejecutable: $targetDemoExe" -ForegroundColor Cyan
Write-Host "No se modifico el build/instalador de produccion." -ForegroundColor Green
