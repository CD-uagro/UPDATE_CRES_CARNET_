# Script para publicar v2.4.32 al sistema de actualizaciones
# Ejecutar DESPUES de que Render funcione correctamente

param(
    [switch]$AllowLegacy,
    [switch]$ConfirmProduction
)

# LEGACY SCRIPT - No usar para releases actuales. Usar version.json + tool/sync_version.ps1 + build_installer.ps1.
if (-not $AllowLegacy -or -not $ConfirmProduction) {
    Write-Error "Script legacy bloqueado: publica metadata v2.4.32 en backend productivo."
    Write-Host "Uso consciente: .\publicar_v2.4.32.ps1 -AllowLegacy -ConfirmProduction" -ForegroundColor Yellow
    exit 1
}

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  PUBLICAR v2.4.32 AL SISTEMA" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verificar que el archivo ZIP existe
$zipPath = "CRES_Carnets_Windows_v2.4.32.zip"
if (-not (Test-Path $zipPath)) {
    Write-Host "ERROR: No se encuentra $zipPath" -ForegroundColor Red
    exit 1
}

# Calcular checksum
Write-Host "Calculando checksum..." -ForegroundColor Yellow
$hash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash
$sizeBytes = (Get-Item $zipPath).Length
$sizeMB = [math]::Round($sizeBytes / 1MB, 2)

Write-Host "Archivo: $zipPath" -ForegroundColor White
Write-Host "TamaÃ±o: $sizeMB MB" -ForegroundColor White
Write-Host "SHA256: $hash" -ForegroundColor White

# Preparar datos para publicar
$updateData = @{
    version = "2.4.32"
    build_number = 32
    download_url = "https://github.com/edukshare-max/UPDATE_CRES_CARNET_/releases/download/v2.4.32/CRES_Carnets_Windows_v2.4.32.zip"
    changelog = @(
        "Busqueda por nombre en Administrar Expedientes",
        "Busqueda instantanea mientras escribes",
        "Funciona con matricula O nombre",
        "Boton para limpiar busqueda rapidamente",
        "Mejoras de rendimiento"
    )
    checksum = $hash
    file_size = $sizeBytes
    release_date = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")    
    minimum_version = "2.4.0"
    required = $false
}

$json = $updateData | ConvertTo-Json -Depth 10

Write-Host "`nJSON a enviar:" -ForegroundColor Yellow
Write-Host $json -ForegroundColor Gray

# Intentar publicar
Write-Host "`nPublicando a Render..." -ForegroundColor Yellow
$url = "https://fastapi-backend-o7ks.onrender.com/updates/publish"

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $json -ContentType "application/json" -TimeoutSec 30
    
    Write-Host "`nâœ… PUBLICADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "Respuesta del servidor:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 5 | Write-Host
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  ACTUALIZACION DISPONIBLE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "`nTodas las apps detectaran la actualizacion" -ForegroundColor White
    Write-Host "en 1-5 minutos y mostraran la notificacion." -ForegroundColor White
    Write-Host "`n========================================`n" -ForegroundColor Green
    
} catch {
    Write-Host "`nâŒ ERROR AL PUBLICAR" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
        
        if ($statusCode -eq 404) {
            Write-Host "`nEl endpoint /updates/publish NO EXISTE todavia." -ForegroundColor Yellow
            Write-Host "Render aun no ha actualizado el codigo." -ForegroundColor Yellow
            Write-Host "`nOpciones:" -ForegroundColor Cyan
            Write-Host "1. Haz Suspend + Resume en Render" -ForegroundColor White
            Write-Host "2. Espera y vuelve a intentar en 5 minutos" -ForegroundColor White
        } else {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`nMientras tanto, puedes distribuir manualmente con:" -ForegroundColor Yellow
    Write-Host "  instalar_v2.4.32.ps1" -ForegroundColor Cyan
    exit 1
}

