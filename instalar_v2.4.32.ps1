# Script de Instalación Rápida - CRES Carnets v2.4.32
# Copia este script junto con el ZIP a la PC de destino y ejecútalo

param(
    [switch]$AllowLegacyInstall
)

# LEGACY SCRIPT - No usar para releases actuales. Usar version.json + tool/sync_version.ps1 + build_installer.ps1.
if (-not $AllowLegacyInstall) {
    Write-Error "Script legacy bloqueado: instala una version antigua y reemplaza la carpeta local."
    Write-Host "Uso consciente: .\instalar_v2.4.32.ps1 -AllowLegacyInstall" -ForegroundColor Yellow
    exit 1
}

$VERSION = "2.4.32"
$ZIP_FILE = "CRES_Carnets_Windows_v2.4.32.zip"
$INSTALL_DIR = "$env:LOCALAPPDATA\CRES_Carnets"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  INSTALADOR CRES Carnets v$VERSION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar que existe el ZIP
if (!(Test-Path $ZIP_FILE)) {
    Write-Host "ERROR: No se encuentra $ZIP_FILE" -ForegroundColor Red
    Write-Host "Asegurate de que este script este en la misma carpeta que el ZIP" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "[1/4] Archivo encontrado: $ZIP_FILE" -ForegroundColor Green

# 2. Cerrar la app si está corriendo
Write-Host "[2/4] Cerrando aplicacion si esta abierta..." -ForegroundColor Yellow
Get-Process -Name "cres_carnets_ibmcloud" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
Write-Host "      Aplicacion cerrada" -ForegroundColor Green

# 3. Crear/limpiar directorio de instalación
Write-Host "[3/4] Preparando directorio de instalacion..." -ForegroundColor Yellow
if (Test-Path $INSTALL_DIR) {
    # Hacer backup de la versión anterior
    $BACKUP_DIR = "$INSTALL_DIR`_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Host "      Haciendo backup en: $BACKUP_DIR" -ForegroundColor Gray
    Move-Item -Path $INSTALL_DIR -Destination $BACKUP_DIR -Force
}
New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
Write-Host "      Directorio listo: $INSTALL_DIR" -ForegroundColor Green

# 4. Extraer archivos
Write-Host "[4/4] Extrayendo archivos..." -ForegroundColor Yellow
Expand-Archive -Path $ZIP_FILE -DestinationPath $INSTALL_DIR -Force
Write-Host "      Archivos extraidos" -ForegroundColor Green

# 5. Crear acceso directo en el escritorio
Write-Host ""
Write-Host "Creando acceso directo en el escritorio..." -ForegroundColor Yellow
$Desktop = [System.Environment]::GetFolderPath('Desktop')
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Desktop\CRES Carnets.lnk")
$Shortcut.TargetPath = "$INSTALL_DIR\cres_carnets_ibmcloud.exe"
$Shortcut.WorkingDirectory = $INSTALL_DIR
$Shortcut.Description = "CRES Carnets - Sistema de Salud UAGro"
$Shortcut.Save()
Write-Host "Acceso directo creado" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  INSTALACION COMPLETADA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Version instalada: $VERSION" -ForegroundColor White
Write-Host "Ubicacion: $INSTALL_DIR" -ForegroundColor White
Write-Host ""
Write-Host "Novedades de esta version:" -ForegroundColor Cyan
Write-Host "  - Busqueda por nombre en 'Administrar Expedientes'" -ForegroundColor White
Write-Host "  - Busqueda por nombre/matricula en 'Nueva Nota'" -ForegroundColor White
Write-Host "  - Filtrado en tiempo real" -ForegroundColor White
Write-Host "  - Mensajes informativos" -ForegroundColor White
Write-Host ""
Write-Host "Presiona Enter para abrir la aplicacion..." -ForegroundColor Yellow
pause

# Abrir la aplicación
Start-Process "$INSTALL_DIR\cres_carnets_ibmcloud.exe"
