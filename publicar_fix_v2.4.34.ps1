# 🚨 FIX DE EMERGENCIA v2.4.34 - Problema de Login en Windows
# Este script sube el fix al sistema de auto-actualización

param(
    [switch]$AllowLegacy,
    [switch]$ConfirmProduction
)

# LEGACY SCRIPT - No usar para releases actuales. Usar version.json + tool/sync_version.ps1 + build_installer.ps1.
if (-not $AllowLegacy -or -not $ConfirmProduction) {
    Write-Error "Script legacy bloqueado: crea tag/release, sube ZIP y publica metadata v2.4.34 en backend productivo."
    Write-Host "Uso consciente: .\publicar_fix_v2.4.34.ps1 -AllowLegacy -ConfirmProduction" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== FIX EMERGENCIA: v2.4.34 ===" -ForegroundColor Red
Write-Host ""

$version = "2.4.34"
$buildNumber = 34
$zipFile = "CRES_Carnets_Windows_v2.4.34_fix_login.zip"
$githubUser = "edukshare-max"
$githubRepo = "UPDATE_CRES_CARNET_"

# Changelog detallado
$changelog = @"
🚨 FIX CRÍTICO: Problema de autenticación en Windows

PROBLEMA RESUELTO:
- ❌ Los usuarios no podían entrar en la app de Windows
- ❌ Las contraseñas eran rechazadas (app móvil funcionaba bien)
- ❌ Causado por timeout muy corto (3 segundos)

CAMBIOS v2.4.34:
✅ Timeout de verificación de internet: 3s → 10s
✅ Timeout de login: 3s → 15s  
✅ Manejo mejorado de cold start de Render.com
✅ Mensajes informativos durante espera

¿POR QUÉ FALLÓ?
El backend en Render.com se "duerme" después de inactividad.
Cuando un usuario en Windows intenta entrar, el backend tarda
5-8 segundos en "despertar" (cold start). El timeout de 3s
era muy corto y causaba que la app pensara que no había internet,
intentaba login offline y fallaba.

IMPACTO:
- App móvil: NO afectada (backend ya despierto por otros usuarios)
- App Windows: AFECTADA (timeout muy corto)

SOLUCIÓN:
Aumentar timeouts para dar tiempo al backend de despertar.
Ahora el login esperará hasta 15 segundos si es necesario.

INSTALACIÓN:
La app se actualizará automáticamente en las próximas horas.
Si necesitas el fix INMEDIATO, descarga e instala manualmente.
"@

Write-Host "📝 CHANGELOG:" -ForegroundColor Yellow
Write-Host $changelog -ForegroundColor Gray
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path $zipFile)) {
    Write-Host "❌ ERROR: No se encontró $zipFile" -ForegroundColor Red
    Write-Host "   Ejecuta primero la compilación" -ForegroundColor Yellow
    exit 1
}

Write-Host "1️⃣  Subiendo a GitHub..." -ForegroundColor Cyan

# Crear tag y release
Write-Host "   Creando tag v$version..." -ForegroundColor Yellow
git tag -a "v$version" -m "FIX CRITICO: Login en Windows (timeout aumentado)"
git push origin "v$version"

Write-Host "   Creando release..." -ForegroundColor Yellow
$releaseBody = $changelog -replace "`n", "\n"
gh release create "v$version" `
    --title "v$version - FIX CRÍTICO: Login Windows" `
    --notes "$releaseBody" `
    --repo "$githubUser/$githubRepo"

Write-Host "   Subiendo archivo ZIP..." -ForegroundColor Yellow
gh release upload "v$version" $zipFile --repo "$githubUser/$githubRepo"

$downloadUrl = "https://github.com/$githubUser/$githubRepo/releases/download/v$version/$zipFile"
Write-Host "   ✅ Release creado" -ForegroundColor Green
Write-Host "   URL: $downloadUrl" -ForegroundColor Gray
Write-Host ""

Write-Host "2️⃣  Publicando en sistema de auto-actualización..." -ForegroundColor Cyan

$publishUrl = "https://fastapi-backend-o7ks.onrender.com/updates/publish"
$publishBody = @{
    version = $version
    build_number = $buildNumber
    platform = "windows"
    download_url = $downloadUrl
    changelog = $changelog
    release_date = (Get-Date).ToString("yyyy-MM-dd")
    is_critical = $true  # CRÍTICO: usuarios no pueden entrar
    min_version = "2.4.0"
} | ConvertTo-Json -Depth 10

Write-Host "   Enviando a: $publishUrl" -ForegroundColor Yellow
Write-Host "   Versión: $version (build $buildNumber)" -ForegroundColor Gray
Write-Host "   CRÍTICO: SÍ (fuerza actualización)" -ForegroundColor Red

try {
    $response = Invoke-RestMethod `
        -Uri $publishUrl `
        -Method POST `
        -Body $publishBody `
        -ContentType "application/json"
    
    Write-Host ""
    Write-Host "✅ PUBLICADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host ""
    Write-Host "Respuesta del servidor:" -ForegroundColor Yellow
    $response | Format-List
    
    Write-Host ""
    Write-Host "=== DISTRIBUCIÓN ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✅ Fix disponible en:" -ForegroundColor Green
    Write-Host "   - Sistema de auto-actualización (forzada)" -ForegroundColor White
    Write-Host "   - GitHub Releases" -ForegroundColor White
    Write-Host ""
    Write-Host "⏰ Tiempo de distribución:" -ForegroundColor Yellow
    Write-Host "   - Auto-update detecta en: 1-5 minutos" -ForegroundColor White
    Write-Host "   - Al abrir la app: descarga automática" -ForegroundColor White
    Write-Host "   - Instalación: manual (extraer ZIP)" -ForegroundColor White
    Write-Host ""
    Write-Host "📱 INSTRUCCIONES PARA USUARIOS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "OPCIÓN A - Auto-actualización (Recomendado):" -ForegroundColor Yellow
    Write-Host "  1. Cierra la app si está abierta" -ForegroundColor White
    Write-Host "  2. Abre la app de nuevo" -ForegroundColor White
    Write-Host "  3. Espera el mensaje de actualización" -ForegroundColor White
    Write-Host "  4. Click en 'Actualizar ahora'" -ForegroundColor White
    Write-Host "  5. Espera la descarga (15 MB)" -ForegroundColor White
    Write-Host "  6. Reemplaza archivos cuando se indique" -ForegroundColor White
    Write-Host ""
    Write-Host "OPCIÓN B - Manual (Si tiene prisa):" -ForegroundColor Yellow
    Write-Host "  1. Descarga: $downloadUrl" -ForegroundColor Gray
    Write-Host "  2. Extrae el ZIP" -ForegroundColor White
    Write-Host "  3. Reemplaza archivos en carpeta de instalación" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  NOTA IMPORTANTE:" -ForegroundColor Red
    Write-Host "  Si el problema persiste después de actualizar:" -ForegroundColor Yellow
    Write-Host "  1. Cierra completamente la app" -ForegroundColor White
    Write-Host "  2. Elimina: C:\Users\[USUARIO]\AppData\Local\cres_carnets_ibmcloud" -ForegroundColor White
    Write-Host "  3. Abre la app de nuevo" -ForegroundColor White
    Write-Host "  4. Intenta login (requiere internet)" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "❌ ERROR al publicar" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Pero el release de GitHub está creado:" -ForegroundColor Yellow
    Write-Host "  $downloadUrl" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Puedes distribuir manualmente el ZIP" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== COMMIT Y PUSH ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "¿Quieres hacer commit del código? (S/N):" -ForegroundColor Yellow
$commit = Read-Host

if ($commit -eq 'S' -or $commit -eq 's') {
    Write-Host ""
    Write-Host "Haciendo commit..." -ForegroundColor Yellow
    git add .
    git commit -m "fix(auth): Aumentar timeouts para cold start de Render.com

- api_service.dart: Timeout internet check 3s -> 10s
- auth_service.dart: Timeout login 3s -> 15s
- Resuelve problema de login en Windows cuando backend dormido
- Version 2.4.34 build 34

Fixes #login-windows-timeout"
    
    Write-Host "Pusheando a GitHub..." -ForegroundColor Yellow
    git push origin master
    
    Write-Host "✅ Código sincronizado" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ FIX COMPLETADO" -ForegroundColor Green
Write-Host ""
