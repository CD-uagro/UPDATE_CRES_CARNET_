# Script para forzar deployment en Render usando webhook
# Si Render no está desplegando automáticamente, este script lo fuerza

param(
    [switch]$AllowLegacy,
    [switch]$ConfirmProduction
)

# LEGACY SCRIPT - No usar para releases actuales. Usar version.json + tool/sync_version.ps1 + build_installer.ps1.
if (-not $AllowLegacy -or -not $ConfirmProduction) {
    Write-Error "Script legacy bloqueado: consulta backend productivo y hace POST de prueba a /updates/publish."
    Write-Host "Uso consciente: .\force_render_deploy.ps1 -AllowLegacy -ConfirmProduction" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== FORZAR DEPLOYMENT EN RENDER ===" -ForegroundColor Cyan
Write-Host ""

# Verificar estado actual del backend
Write-Host "1. Verificando estado actual del backend..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "https://fastapi-backend-o7ks.onrender.com/health" -TimeoutSec 10
    Write-Host "   Backend está activo" -ForegroundColor Green
    Write-Host "   Cosmos conectado: $($health.cosmos_connected)" -ForegroundColor Gray
} catch {
    Write-Host "   WARNING: Backend no responde" -ForegroundColor Red
}

Write-Host ""
Write-Host "2. Verificando si endpoint /carnet/search existe..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://fastapi-backend-o7ks.onrender.com/carnet/search?nombre=test" -Method Get -ErrorAction Stop
    Write-Host "   ✅ Endpoint existe (código: $($response.StatusCode))" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        $content = $_.ErrorDetails.Message
        if ($content -like "*No se encontr*carnet*") {
            Write-Host "   ✅ Endpoint existe (404 es esperado sin datos)" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Endpoint NO existe - Render no ha desplegado" -ForegroundColor Red
            Write-Host "   Respuesta: $content" -ForegroundColor Gray
        }
    } else {
        Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "3. Verificando si endpoint /updates/publish existe..." -ForegroundColor Yellow
try {
    # Intentar POST con datos vacíos para ver si el endpoint existe
    $testJson = '{"version":"test"}' 
    $response = Invoke-WebRequest -Uri "https://fastapi-backend-o7ks.onrender.com/updates/publish" -Method Post -ContentType "application/json" -Body $testJson -ErrorAction Stop
    Write-Host "   ✅ Endpoint existe" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Host "   ❌ Endpoint NO existe - Render no ha desplegado" -ForegroundColor Red
    } elseif ($_.Exception.Response.StatusCode.value__ -eq 400 -or $_.Exception.Response.StatusCode.value__ -eq 422) {
        Write-Host "   ✅ Endpoint existe (error de validación es esperado)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Estado desconocido: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== DIAGNÓSTICO ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "El problema es que Render NO está desplegando los commits automáticamente." -ForegroundColor Yellow
Write-Host ""
Write-Host "SOLUCIONES POSIBLES:" -ForegroundColor White
Write-Host ""
Write-Host "A) MANUAL - Dashboard de Render:" -ForegroundColor Cyan
Write-Host "   1. Ve a: https://dashboard.render.com/" -ForegroundColor Gray
Write-Host "   2. Busca el servicio: fastapi-backend-o7ks" -ForegroundColor Gray
Write-Host "   3. Haz clic en 'Manual Deploy' > 'Deploy latest commit'" -ForegroundColor Gray
Write-Host "   4. Espera 2-3 minutos" -ForegroundColor Gray
Write-Host ""
Write-Host "B) API de Render (requiere API key):" -ForegroundColor Cyan
Write-Host "   Si tienes un API key de Render, puedo crear un script para deployar automáticamente" -ForegroundColor Gray
Write-Host ""
Write-Host "C) Verificar configuración de Webhooks en GitHub:" -ForegroundColor Cyan
Write-Host "   1. Ve a: https://github.com/edukshare-max/fastapi-backend/settings/hooks" -ForegroundColor Gray
Write-Host "   2. Verifica que haya un webhook de Render activo" -ForegroundColor Gray
Write-Host "   3. Revisa los 'Recent Deliveries' para ver si hay errores" -ForegroundColor Gray
Write-Host ""
Write-Host "D) Forzar push vacío (ya intentado):" -ForegroundColor Cyan
Write-Host "   git commit --allow-empty -m 'force deploy' && git push" -ForegroundColor Gray
Write-Host ""

Write-Host "¿Tienes acceso al dashboard de Render o un API key?" -ForegroundColor Yellow
Write-Host ""
