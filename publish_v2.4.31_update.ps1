# Script para publicar la actualización v2.4.31 al servidor FastAPI
# Este script envía la metadata al backend para que las apps puedan detectar la actualización

param(
    [switch]$AllowLegacy,
    [switch]$ConfirmProduction
)

# LEGACY SCRIPT - No usar para releases actuales. Usar version.json + tool/sync_version.ps1 + build_installer.ps1.
if (-not $AllowLegacy -or -not $ConfirmProduction) {
    Write-Error "Script legacy bloqueado: publica metadata antigua en backend productivo."
    Write-Host "Uso consciente: .\publish_v2.4.31_update.ps1 -AllowLegacy -ConfirmProduction" -ForegroundColor Yellow
    exit 1
}

$API_URL = "https://fastapi-backend-o7ks.onrender.com/updates/publish"
$JSON_FILE = "version_2.4.31.json"

Write-Host "`n=== PUBLICAR ACTUALIZACION v2.4.31 ===" -ForegroundColor Cyan
Write-Host ""

# Leer el archivo JSON
if (!(Test-Path $JSON_FILE)) {
    Write-Host "ERROR: No se encuentra $JSON_FILE" -ForegroundColor Red
    exit 1
}

$jsonContent = Get-Content $JSON_FILE -Raw

Write-Host "Leyendo metadata..." -ForegroundColor Yellow
Write-Host $jsonContent
Write-Host ""

# Enviar al servidor
Write-Host "Enviando al servidor..." -ForegroundColor Yellow
Write-Host "URL: $API_URL"
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $API_URL `
        -Method Post `
        -ContentType "application/json" `
        -Body $jsonContent `
        -TimeoutSec 30
    
    Write-Host "✅ EXITO: Actualizacion v2.4.31 publicada!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Respuesta del servidor:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "¡Las aplicaciones instaladas detectaran la actualizacion automaticamente!" -ForegroundColor Green
    Write-Host "Tiempo de sincronizacion: 1-5 minutos" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR al publicar actualizacion:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Detalles del error:" -ForegroundColor Yellow
    Write-Host $_.ErrorDetails.Message
    Write-Host ""
    Write-Host "ALTERNATIVA: Publicar manualmente con curl:" -ForegroundColor Cyan
    Write-Host "curl -X POST $API_URL -H 'Content-Type: application/json' -d '@$JSON_FILE'"
    exit 1
}
