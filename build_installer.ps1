# ====================================================================
# Script para generar instalador de CRES Carnets
# ====================================================================

param(
    [switch]$SkipBuild,
    [switch]$OpenFolder,
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"

function Stop-Build {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "GENERADOR DE INSTALADOR - CRES Carnets UAGro" -ForegroundColor Yellow
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "pubspec.yaml")) {
    Stop-Build "Debe ejecutar este script desde la raiz del proyecto."
}

# Guard rail: version.json es la fuente canonica y los derivados deben coincidir.
$syncVersionScript = "tool\sync_version.ps1"
if (-not (Test-Path $syncVersionScript)) {
    Stop-Build "No se encontro $syncVersionScript. No se puede validar la consistencia de versiones."
}

Write-Host "Verificando consistencia de versiones..." -ForegroundColor Yellow
& powershell -ExecutionPolicy Bypass -File $syncVersionScript -CheckOnly
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Versiones inconsistentes. Build detenido antes de compilar o generar instalador." -ForegroundColor Red
    Write-Host "Ejecuta: powershell -ExecutionPolicy Bypass -File tool\sync_version.ps1" -ForegroundColor Yellow
    exit 1
}

# Leer version actual desde fuente canonica
$versionFile = Get-Content "version.json" -Raw | ConvertFrom-Json
$version = [string]$versionFile.version
$buildNumber = [int]$versionFile.buildNumber
Write-Host "Version: $version (Build $buildNumber)" -ForegroundColor Cyan

# Validar nombre esperado del instalador contra version.json.artifact.fileName
$expectedInstallerNameFromVersion = "CRES_Carnets_Setup_v$version.exe"
$installerName = [string]$versionFile.artifact.fileName
if ([string]::IsNullOrWhiteSpace($installerName)) {
    Stop-Build "version.json debe definir artifact.fileName."
}
if ($installerName -ne $expectedInstallerNameFromVersion) {
    Write-Host "ERROR: artifact.fileName no coincide con version.json.version" -ForegroundColor Red
    Write-Host "   version.json.version: $version" -ForegroundColor Gray
    Write-Host "   artifact.fileName:    $installerName" -ForegroundColor Gray
    Write-Host "   esperado:             $expectedInstallerNameFromVersion" -ForegroundColor Gray
    exit 1
}
Write-Host "Instalador esperado: $installerName" -ForegroundColor Green

if ($ValidateOnly) {
    Write-Host "Validacion OK. No se compilo ni se genero instalador." -ForegroundColor Green
    exit 0
}

# Paso 1: Build de la aplicacion Flutter
if (-not $SkipBuild) {
    Write-Host ""
    Write-Host "Paso 1/4: Compilando aplicacion Flutter (Release)..." -ForegroundColor Yellow
    Write-Host "Esto puede tomar varios minutos..." -ForegroundColor Gray

    flutter clean | Out-Null
    flutter pub get | Out-Null

    $buildOutput = flutter build windows --release 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error en la compilacion de Flutter" -ForegroundColor Red
        Write-Host $buildOutput -ForegroundColor Gray
        exit 1
    }

    Write-Host "Compilacion exitosa" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Paso 1/4: Omitiendo compilacion (usando build existente)" -ForegroundColor Yellow
}

# Paso 2: Verificar que existe el build
Write-Host ""
Write-Host "Paso 2/4: Verificando archivos..." -ForegroundColor Yellow

$exePath = "build\windows\x64\runner\Release\cres_carnets_ibmcloud.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "Error: No se encontro el ejecutable compilado" -ForegroundColor Red
    Write-Host "Ruta esperada: $exePath" -ForegroundColor Gray
    exit 1
}

$exeSize = (Get-Item $exePath).Length / 1MB
Write-Host "Ejecutable encontrado ($([math]::Round($exeSize, 2)) MB)" -ForegroundColor Green

# Verificar Inno Setup
$innoPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $innoPath)) {
    Write-Host ""
    Write-Host "Error: Inno Setup no esta instalado" -ForegroundColor Red
    Write-Host ""
    Write-Host "Descarga e instala Inno Setup 6:" -ForegroundColor Yellow
    Write-Host "https://jrsoftware.org/isdl.php" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Despues de instalar, vuelve a ejecutar este script." -ForegroundColor Gray
    exit 1
}

Write-Host "Inno Setup encontrado" -ForegroundColor Green

# Paso 3: Crear directorio de salida
Write-Host ""
Write-Host "Paso 3/4: Preparando directorio de salida..." -ForegroundColor Yellow

$outputDir = "releases\installers"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "Directorio listo: $outputDir" -ForegroundColor Green

# Paso 4: Generar instalador con Inno Setup
Write-Host ""
Write-Host "Paso 4/4: Generando instalador..." -ForegroundColor Yellow
Write-Host "Esto puede tomar 1-2 minutos..." -ForegroundColor Gray

$scriptPath = "installer\setup_script.iss"
$innoOutput = & $innoPath $scriptPath 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al generar el instalador" -ForegroundColor Red
    Write-Host $innoOutput -ForegroundColor Gray
    exit 1
}

Write-Host "Instalador generado exitosamente" -ForegroundColor Green

# Verificar el instalador generado
$installerPath = Join-Path $outputDir $installerName

if (Test-Path $installerPath) {
    $installerSize = (Get-Item $installerPath).Length / 1MB

    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "INSTALADOR CREADO EXITOSAMENTE" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Archivo: $installerName" -ForegroundColor Cyan
    Write-Host "Tamano: $([math]::Round($installerSize, 2)) MB" -ForegroundColor Cyan
    Write-Host "Ubicacion: $(Resolve-Path $installerPath)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Proximos pasos:" -ForegroundColor Yellow
    Write-Host "1. Prueba el instalador en otra computadora" -ForegroundColor Gray
    Write-Host "2. Distribuye el archivo .exe a tus companeros" -ForegroundColor Gray
    Write-Host "3. Los usuarios solo necesitan ejecutar el instalador" -ForegroundColor Gray
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Green

    # Abrir carpeta si se solicito
    if ($OpenFolder) {
        Write-Host ""
        Write-Host "Abriendo carpeta de salida..." -ForegroundColor Cyan
        Start-Process explorer.exe -ArgumentList (Resolve-Path $outputDir)
    }
} else {
    Write-Host ""
    Write-Host "Error: El instalador no se genero correctamente" -ForegroundColor Red
    Write-Host "Esperado: $installerPath" -ForegroundColor Gray
    exit 1
}

Write-Host ""
