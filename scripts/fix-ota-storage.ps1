#Requires -Version 5.1
<#
.SYNOPSIS
  Envia o APK release para Supabase Storage (bucket público app-releases)
  e atualiza app_update_manifest.apk_url — corrige 404 com repo GitHub privado.

.EXAMPLE
  .\scripts\fix-ota-storage.ps1
  .\scripts\fix-ota-storage.ps1 -ApkPath build\app\outputs\flutter-apk\app-release.apk
#>
param(
    [string] $ApkPath = 'build/app/outputs/flutter-apk/app-release.apk'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

function Load-EnvFile([string]$path) {
    if (-not (Test-Path $path)) { throw "Arquivo $path não encontrado." }
    Get-Content $path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }
        $i = $line.IndexOf('=')
        if ($i -lt 1) { return }
        $name = $line.Substring(0, $i).Trim()
        $value = $line.Substring($i + 1).Trim().Trim('"').Trim("'")
        [Environment]::SetEnvironmentVariable($name, $value, 'Process')
    }
}

Load-EnvFile (Join-Path $root '.env.release')

$pubspec = Get-Content 'pubspec.yaml' -Raw
if ($pubspec -notmatch 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    throw 'pubspec.yaml: version inválida.'
}
$semver = "$($Matches[1]).$($Matches[2]).$($Matches[3])"
$build = [int]$Matches[4]
$apkName = "facilite-plus-$semver.apk"

$apkFull = Join-Path $root $ApkPath
if (-not (Test-Path $apkFull)) { throw "APK não encontrado: $apkFull" }

$baseUrl = $env:SUPABASE_URL.TrimEnd('/')
$key = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $baseUrl -or -not $key) { throw 'SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY ausentes em .env.release' }

Write-Host "Upload: app-releases/$apkName" -ForegroundColor Cyan
$bytes = [System.IO.File]::ReadAllBytes($apkFull)
Invoke-RestMethod -Uri "$baseUrl/storage/v1/object/app-releases/$apkName" -Method Post -Headers @{
    Authorization = "Bearer $key"
    apikey        = $key
    'Content-Type' = 'application/vnd.android.package-archive'
    'x-upsert'    = 'true'
} -Body $bytes | Out-Null

$publicUrl = "$baseUrl/storage/v1/object/public/app-releases/$apkName"
Write-Host "OTA URL: $publicUrl" -ForegroundColor Green

$body = @{
    version    = $semver
    build      = $build
    apk_url    = $publicUrl
    updated_at = (Get-Date).ToUniversalTime().ToString('o')
} | ConvertTo-Json -Compress

Invoke-RestMethod -Uri "$baseUrl/rest/v1/app_update_manifest?id=eq.1" -Method Patch -Headers @{
    Authorization  = "Bearer $key"
    apikey         = $key
    'Content-Type' = 'application/json'
    Prefer         = 'return=minimal'
} -Body $body | Out-Null

Write-Host "Manifesto atualizado (v$semver build $build)." -ForegroundColor Green
