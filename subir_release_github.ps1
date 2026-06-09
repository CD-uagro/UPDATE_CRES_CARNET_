# Script para subir release v2.4.32 a GitHub automáticamente
# Requiere: Personal Access Token con scope 'repo'

param(
    [string]$Token = $env:GITHUB_TOKEN,
    [switch]$AllowLegacy,
    [switch]$ConfirmProduction
)

# LEGACY SCRIPT - No usar para releases actuales. Usar version.json + tool/sync_version.ps1 + build_installer.ps1.
if (-not $AllowLegacy -or -not $ConfirmProduction) {
    Write-Error "Script legacy bloqueado: crea releases antiguas en GitHub y modifica scripts legacy."
    Write-Host "Uso consciente: .\subir_release_github.ps1 -AllowLegacy -ConfirmProduction" -ForegroundColor Yellow
    exit 1
}

$ErrorActionPreference = "Stop"

# Configuración
$repo = "edukshare-max/UPDATE_CRES_CARNET_"
$tag = "v2.4.32"
$zipFile = "CRES_Carnets_Windows_v2.4.32.zip"
$releaseName = "CRES Carnets v2.4.32 - Busqueda por Nombre"
$releaseBody = "Nueva version v2.4.32`n`nNuevas Funcionalidades:`n- Busqueda por nombre en Administrar Expedientes`n- Busqueda instantanea mientras escribes`n- Funciona con matricula O nombre`n- Boton para limpiar busqueda rapidamente`n`nMejoras Tecnicas:`n- Optimizacion de rendimiento en busquedas`n- Mejor experiencia de usuario en filtros`n- Backend actualizado con endpoint /carnet/search`n`nInstalacion: Descarga el archivo ZIP y ejecuta el instalador incluido."

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  SUBIR RELEASE A GITHUB" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verificar token
if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Host "ERROR: No se encontró GITHUB_TOKEN" -ForegroundColor Red
    Write-Host "`nOpciones:" -ForegroundColor Yellow
    Write-Host "1. Ejecuta: " -NoNewline -ForegroundColor White
    Write-Host '$env:GITHUB_TOKEN = "tu-token-aqui"' -ForegroundColor Green
    Write-Host "2. O pasa el token: " -NoNewline -ForegroundColor White
    Write-Host '.\subir_release_github.ps1 -Token "tu-token"' -ForegroundColor Green
    Write-Host "`nCrea un token en: https://github.com/settings/tokens/new" -ForegroundColor Cyan
    Write-Host "Scope requerido: repo (full control)" -ForegroundColor Yellow
    exit 1
}

# Verificar archivo
if (-not (Test-Path $zipFile)) {
    Write-Host "ERROR: No se encuentra $zipFile" -ForegroundColor Red
    exit 1
}

$sizeBytes = (Get-Item $zipFile).Length
$sizeMB = [math]::Round($sizeBytes / 1MB, 2)
$hash = (Get-FileHash -Path $zipFile -Algorithm SHA256).Hash

Write-Host "Archivo: $zipFile" -ForegroundColor White
Write-Host "Tamaño: $sizeMB MB" -ForegroundColor White
Write-Host "SHA256: $hash" -ForegroundColor White

# Headers para API de GitHub
$headers = @{
    "Authorization" = "Bearer $Token"
    "Accept" = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

try {
    # 1. Crear release
    Write-Host "`nCreando release en GitHub..." -ForegroundColor Yellow
    $releaseData = @{
        tag_name = $tag
        name = $releaseName
        body = $releaseBody
        draft = $false
        prerelease = $false
    } | ConvertTo-Json

    $createUrl = "https://api.github.com/repos/$repo/releases"
    $release = Invoke-RestMethod -Uri $createUrl -Method Post -Headers $headers -Body $releaseData -ContentType "application/json"
    
    Write-Host "✅ Release creado: $($release.html_url)" -ForegroundColor Green

    # 2. Subir archivo ZIP
    Write-Host "`nSubiendo archivo ZIP..." -ForegroundColor Yellow
    $uploadUrl = $release.upload_url -replace '\{\?.*\}', "?name=$zipFile"
    
    $uploadHeaders = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/zip"
    }

    $fileBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $zipFile))
    $asset = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -Body $fileBytes

    Write-Host "✅ Archivo subido: $($asset.browser_download_url)" -ForegroundColor Green

    # 3. Actualizar script de publicación con URL correcta
    Write-Host "`nActualizando publicar_v2.4.32.ps1..." -ForegroundColor Yellow
    $downloadUrl = $asset.browser_download_url
    
    $publishScript = Get-Content "publicar_v2.4.32.ps1" -Raw
    $publishScript = $publishScript -replace 'https://tu-servidor\.com/releases/CRES_Carnets_Windows_v2\.4\.32\.zip', $downloadUrl
    $publishScript | Set-Content "publicar_v2.4.32.ps1" -Encoding UTF8

    Write-Host "✅ Script actualizado con URL de descarga" -ForegroundColor Green

    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  ✅ RELEASE PUBLICADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "`nURL del release:" -ForegroundColor Cyan
    Write-Host $release.html_url -ForegroundColor White
    Write-Host "`nURL de descarga:" -ForegroundColor Cyan
    Write-Host $downloadUrl -ForegroundColor White
    Write-Host "`nAhora ejecuta:" -ForegroundColor Yellow
    Write-Host "  .\publicar_v2.4.32.ps1" -ForegroundColor Green
    Write-Host "`nPara publicar la actualización a todas las apps.`n" -ForegroundColor White

} catch {
    Write-Host "`n❌ ERROR" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.ErrorDetails.Message) {
        $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "`nDetalles:" -ForegroundColor Yellow
        Write-Host $errorJson.message -ForegroundColor Red
    }
    
    exit 1
}
