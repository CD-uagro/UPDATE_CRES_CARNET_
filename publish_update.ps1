# Script para publicar la actualización al servidor FastAPI
# Este script envía la metadata al backend para que las apps puedan detectar la actualización

param(
    [switch]$AllowLegacy,
    [switch]$ConfirmProduction
)

# LEGACY SCRIPT - No usar para releases actuales. Usar version.json + tool/sync_version.ps1 + build_installer.ps1.
if (-not $AllowLegacy -or -not $ConfirmProduction) {
    Write-Error "Script legacy bloqueado: publica metadata antigua en backend productivo."
    Write-Host "Uso consciente: .\publish_update.ps1 -AllowLegacy -ConfirmProduction" -ForegroundColor Yellow
    exit 1
}

$API_URL = "https://fastapi-backend-o7ks.onrender.com/updates/publish"
$JSON_FILE = "version_2.4.30.json"

Write-Host "`n=== PUBLICAR ACTUALIZACION v2.4.30 ===" -ForegroundColor Cyan
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
    
    Write-Host "EXITO: Actualizacion publicada!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Respuesta del servidor:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10
    Write-Host ""
    Write-Host "Las aplicaciones instaladas detectaran la actualizacion automaticamente!" -ForegroundColor Green
    Write-Host "Tiempo de sincronizacion: 1-5 minutos" -ForegroundColor Gray
    
} catch {
    Write-Host "ERROR al publicar actualizacion:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Detalles del error:" -ForegroundColor Yellow
    Write-Host $_.ErrorDetails.Message
    Write-Host ""
    Write-Host "ALTERNATIVA: Publicar manualmente con curl:" -ForegroundColor Cyan
    Write-Host "curl -X POST $API_URL -H 'Content-Type: application/json' -d '@$JSON_FILE'"
}

Write-Host ""
Write-Host "NOTA IMPORTANTE:" -ForegroundColor Yellow
Write-Host "Debes subir primero el archivo ZIP a GitHub Releases:" -ForegroundColor White
Write-Host "  1. Ve a https://github.com/edukshare-max/UPDATE_CRES_CARNET_/releases"
Write-Host "  2. Click en 'Draft a new release'"
Write-Host "  3. Tag: v2.4.30"
Write-Host "  4. Sube: CRES_Carnets_Windows_v2.4.30.zip"
Write-Host "  5. Publica el release"
Write-Host ""
Write-Host "Una vez subido el ZIP, las apps podran descargarlo!" -ForegroundColor Green
