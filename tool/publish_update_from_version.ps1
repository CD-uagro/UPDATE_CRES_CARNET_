param(
    [switch]$Publish,
    [switch]$ConfirmProduction,
    [switch]$RequireArtifact,
    [switch]$RequireDownloadUrl,
    [string]$RemoteLatestVersion
)

$ErrorActionPreference = "Stop"

function Fail {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

function Warn {
    param([string]$Message)
    Write-Host "WARNING: $Message" -ForegroundColor Yellow
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Fail "No se encontro: $Path"
    }
    return Get-Content $Path -Raw | ConvertFrom-Json
}

function Get-VersionParts {
    param([string]$Version)

    if ([string]::IsNullOrWhiteSpace($Version)) {
        Fail "Version vacia para comparacion semantica."
    }

    $cleanVersion = ($Version -split '[-+]')[0]
    $parts = $cleanVersion.Split('.')
    $numbers = New-Object System.Collections.Generic.List[int]

    foreach ($part in $parts) {
        if ($part -notmatch '^\d+$') {
            Fail "Version semantica invalida: $Version"
        }
        $numbers.Add([int]$part)
    }

    while ($numbers.Count -lt 3) {
        $numbers.Add(0)
    }

    return $numbers
}

function Compare-SemanticVersion {
    param(
        [string]$Left,
        [string]$Right
    )

    $leftParts = Get-VersionParts $Left
    $rightParts = Get-VersionParts $Right
    $maxParts = [Math]::Max($leftParts.Count, $rightParts.Count)

    for ($i = 0; $i -lt $maxParts; $i++) {
        $leftValue = 0
        $rightValue = 0

        if ($i -lt $leftParts.Count) {
            $leftValue = $leftParts[$i]
        }
        if ($i -lt $rightParts.Count) {
            $rightValue = $rightParts[$i]
        }

        if ($leftValue -gt $rightValue) {
            return 1
        }
        if ($leftValue -lt $rightValue) {
            return -1
        }
    }

    return 0
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$versionPath = Join-Path $repoRoot "version.json"
$syncVersionScript = Join-Path $repoRoot "tool\sync_version.ps1"
$installerOutputDir = Join-Path $repoRoot "releases\installers"
$metadataOutputDir = Join-Path $repoRoot "dist\update_metadata"
$updatesEndpoint = "https://fastapi-backend-o7ks.onrender.com/updates/publish"

if ($Publish -and -not $ConfirmProduction) {
    Fail "Se solicito -Publish, pero falta -ConfirmProduction. No se tocara backend."
}

if (-not (Test-Path $syncVersionScript)) {
    Fail "No se encontro $syncVersionScript."
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "GENERADOR SEGURO DE METADATA DE UPDATE - CRES Carnets UAGro" -ForegroundColor Yellow
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Validando consistencia local de versiones..." -ForegroundColor Yellow
& powershell -ExecutionPolicy Bypass -File $syncVersionScript -CheckOnly
if ($LASTEXITCODE -ne 0) {
    Fail "tool\sync_version.ps1 -CheckOnly fallo. Corrige versiones antes de generar metadata."
}

$versionInfo = Read-JsonFile $versionPath
$version = [string]$versionInfo.version
$buildNumber = [int]$versionInfo.buildNumber
$minimumVersion = [string]$versionInfo.minimumVersion
$channel = [string]$versionInfo.channel
$releaseDate = [string]$versionInfo.releaseDate

if ([string]::IsNullOrWhiteSpace($version)) {
    Fail "version.json no contiene version."
}
if ($buildNumber -le 0) {
    Fail "version.json debe contener buildNumber mayor a 0."
}
if ($null -eq $versionInfo.artifact) {
    Fail "version.json debe contener artifact."
}

$fileName = [string]$versionInfo.artifact.fileName
$downloadUrl = [string]$versionInfo.artifact.downloadUrl
$versionJsonSha256 = [string]$versionInfo.artifact.sha256
$versionJsonFileSize = [int64]$versionInfo.artifact.fileSize

if ([string]::IsNullOrWhiteSpace($fileName)) {
    Fail "version.json artifact.fileName esta vacio."
}

$expectedFileName = "CRES_Carnets_Setup_v$version.exe"
if ($fileName -ne $expectedFileName) {
    Fail "artifact.fileName '$fileName' no coincide con la version '$version'. Esperado: $expectedFileName"
}

if (-not [string]::IsNullOrWhiteSpace($RemoteLatestVersion)) {
    $comparison = Compare-SemanticVersion $version $RemoteLatestVersion
    if ($comparison -le 0) {
        Fail "Publicacion bloqueada: version local $version no es mayor que RemoteLatestVersion $RemoteLatestVersion."
    }
}

if ([string]::IsNullOrWhiteSpace($downloadUrl)) {
    if ($RequireDownloadUrl) {
        Fail "artifact.downloadUrl esta vacio y se paso -RequireDownloadUrl."
    }
    Warn "artifact.downloadUrl esta vacio. En dry-run se permite, pero no es publicable."
}

if ([string]::IsNullOrWhiteSpace($versionJsonSha256)) {
    Warn "artifact.sha256 esta vacio en version.json; se usara checksum real solo si el artefacto existe."
}

$artifactPath = Join-Path $installerOutputDir $fileName
$artifactExists = Test-Path $artifactPath
$calculatedSha256 = ""
$calculatedFileSize = 0

if ($artifactExists) {
    $artifactItem = Get-Item $artifactPath
    $calculatedFileSize = [int64]$artifactItem.Length
    $calculatedSha256 = (Get-FileHash -Path $artifactPath -Algorithm SHA256).Hash
} elseif ($RequireArtifact) {
    Fail "No existe el artefacto requerido: $artifactPath"
} else {
    Warn "No existe el artefacto esperado: $artifactPath"
}

$metadataSha256 = $calculatedSha256
if ([string]::IsNullOrWhiteSpace($metadataSha256)) {
    $metadataSha256 = $versionJsonSha256
}

$metadataFileSize = $calculatedFileSize
if ($metadataFileSize -le 0 -and $versionJsonFileSize -gt 0) {
    $metadataFileSize = $versionJsonFileSize
}

$metadata = [ordered]@{
    version = $version
    buildNumber = $buildNumber
    minimumVersion = $minimumVersion
    channel = $channel
    fileName = $fileName
    downloadUrl = $downloadUrl
    sha256 = $metadataSha256
    fileSize = $metadataFileSize
    releaseDate = $releaseDate
    changelog = @($versionInfo.changelog)
}

if (-not (Test-Path $metadataOutputDir)) {
    New-Item -ItemType Directory -Path $metadataOutputDir -Force | Out-Null
}

$metadataPath = Join-Path $metadataOutputDir "version_$version.json"
$metadataJson = $metadata | ConvertTo-Json -Depth 10
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($metadataPath, $metadataJson, $utf8NoBom)

Write-Host ""
Write-Host "Resumen:" -ForegroundColor Cyan
Write-Host "  Version local:      $version"
Write-Host "  Build:              $buildNumber"
Write-Host "  Archivo esperado:   $fileName"
Write-Host "  Ruta artefacto:     $artifactPath"
Write-Host "  Artefacto existe:   $artifactExists"
if ($artifactExists) {
    Write-Host "  SHA256 calculado:   $calculatedSha256"
    Write-Host "  File size real:     $calculatedFileSize"
} else {
    Write-Host "  SHA256 calculado:   No disponible"
    Write-Host "  File size real:     No disponible"
}
Write-Host "  Metadata generada:  $metadataPath"
Write-Host "  Endpoint destino:   $updatesEndpoint"

if ($Publish) {
    Write-Host "  Estado:             PUBLISH SOLICITADO" -ForegroundColor Yellow
    Write-Host ""

    if (-not $ConfirmProduction) {
        Fail "Se solicito -Publish, pero falta -ConfirmProduction. No se tocara backend."
    }
    if ([string]::IsNullOrWhiteSpace($RemoteLatestVersion)) {
        Fail "Para publicar debes pasar -RemoteLatestVersion con la version actual del backend."
    }
    if ([string]::IsNullOrWhiteSpace($downloadUrl)) {
        Fail "No se puede publicar: artifact.downloadUrl esta vacio."
    }
    if ([string]::IsNullOrWhiteSpace($metadataSha256)) {
        Fail "No se puede publicar: sha256 esta vacio."
    }
    if ($metadataFileSize -le 0) {
        Fail "No se puede publicar: fileSize debe ser mayor a 0."
    }
    if (-not $artifactExists) {
        Fail "No se puede publicar: el artefacto local no existe."
    }

    $publishPayload = [ordered]@{
        version = $metadata.version
        build_number = $metadata.buildNumber
        release_date = $metadata.releaseDate
        download_url = $metadata.downloadUrl
        changelog = $metadata.changelog
        checksum = $metadata.sha256
        file_size = $metadata.fileSize
        minimum_version = $metadata.minimumVersion
        required = $false
    }

    $publishJson = $publishPayload | ConvertTo-Json -Depth 10

    Write-Host "Publicando metadata validada al backend..." -ForegroundColor Yellow
    Write-Host "  Endpoint:           $updatesEndpoint"
    Write-Host "  Version remota:     $RemoteLatestVersion"
    Write-Host "  Version a publicar: $version"

    try {
        $response = Invoke-RestMethod -Uri $updatesEndpoint `
            -Method Post `
            -ContentType "application/json" `
            -Body $publishJson `
            -TimeoutSec 30

        Write-Host ""
        Write-Host "Publicacion completada." -ForegroundColor Green
        $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Host ""
        Write-Host "ERROR al publicar metadata:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow
        }
        exit 1
    }

    exit 0
}

Write-Host "  Estado:             DRY-RUN (no publica)" -ForegroundColor Green
Write-Host ""
Write-Host "DRY-RUN completado. No se publico nada." -ForegroundColor Green
