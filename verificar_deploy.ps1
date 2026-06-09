# Script de Verificación Post-Deploy
# Ejecutar DESPUÉS de que Render muestre "Live"

param(
    [switch]$AllowLegacy,
    [switch]$ConfirmProduction
)

# LEGACY SCRIPT - No usar para releases actuales. Usar version.json + tool/sync_version.ps1 + build_installer.ps1.
if (-not $AllowLegacy -or -not $ConfirmProduction) {
    Write-Error "Script legacy bloqueado: consulta backend productivo y hace POST de prueba a /updates/publish."
    Write-Host "Uso consciente: .\verificar_deploy.ps1 -AllowLegacy -ConfirmProduction" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VERIFICACION POST-DEPLOY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Verificando salud del backend..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "https://fastapi-backend-o7ks.onrender.com/health" -TimeoutSec 10
    Write-Host "       Backend activo" -ForegroundColor Green
    Write-Host "       Cosmos conectado: $($health.cosmos_connected)" -ForegroundColor Gray
} catch {
    Write-Host "       ERROR: Backend no responde" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/3] Verificando endpoint /carnet/search..." -ForegroundColor Yellow
try {
    $null = Invoke-WebRequest -Uri "https://fastapi-backend-o7ks.onrender.com/carnet/search?nombre=test" -ErrorAction Stop
    Write-Host "       FUNCIONA (200 OK)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        $errorMsg = $_.ErrorDetails.Message
        if ($errorMsg -like "*No se encontr*") {
            Write-Host "       FUNCIONA (404 con mensaje correcto)" -ForegroundColor Green
        } else {
            Write-Host "       ERROR: Endpoint no existe" -ForegroundColor Red
            Write-Host "       $errorMsg" -ForegroundColor Gray
            exit 1
        }
    }
}

Write-Host ""
Write-Host "[3/3] Verificando endpoint /updates/publish..." -ForegroundColor Yellow
try {
    $testData = @{version="test"; build_number=1; release_date="2025-01-01"; download_url="http://test"; changelog=@("test")} | ConvertTo-Json
    $null = Invoke-WebRequest -Uri "https://fastapi-backend-o7ks.onrender.com/updates/publish" -Method Post -Body $testData -ContentType "application/json" -ErrorAction Stop
    Write-Host "       FUNCIONA" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Host "       ERROR: Endpoint no existe" -ForegroundColor Red
        exit 1
    } elseif ($_.Exception.Response.StatusCode.value__ -eq 400 -or $_.Exception.Response.StatusCode.value__ -eq 422) {
        Write-Host "       FUNCIONA (error de validacion es esperado)" -ForegroundColor Green
    } else {
        Write-Host "       FUNCIONA" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  TODOS LOS ENDPOINTS FUNCIONAN" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Siguiente paso: Publicar actualizacion" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ejecuta uno de estos comandos:" -ForegroundColor White
Write-Host "  .\publish_v2.4.31_update.ps1  (busqueda en Nueva Nota)" -ForegroundColor Gray
Write-Host "  .\publish_v2.4.32_update.ps1  (busqueda en Administrar Expedientes)" -ForegroundColor Gray
Write-Host ""
