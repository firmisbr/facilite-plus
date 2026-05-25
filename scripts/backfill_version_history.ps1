<#
.SYNOPSIS
  Preenche app_version_history no Supabase a partir das GitHub Releases.

.EXAMPLE
  .\scripts\backfill_version_history.ps1
#>
param(
    [string]$Repo = 'firmisbr/facilite-plus'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

function Load-EnvFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Arquivo $Path não encontrado. Copie .env.release.example para .env.release."
    }
    Get-Content $Path | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -notmatch '=') { return }
        $k, $v = $_ -split '=', 2
        [Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim().Trim('"'))
    }
}

function Get-BuildFromVersion {
    param([string]$Version)
    $parts = $Version -split '\.'
    if ($parts.Count -ge 3) {
        return [int]$parts[2] + ([int]$parts[1] * 10)
    }
    return 1
}

Load-EnvFile (Join-Path $root '.env.release')

$baseUrl = [Environment]::GetEnvironmentVariable('SUPABASE_URL').TrimEnd('/')
$key = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_ROLE_KEY')
if (-not $baseUrl) { throw 'SUPABASE_URL ausente em .env.release' }
if (-not $key) { throw 'SUPABASE_SERVICE_ROLE_KEY ausente em .env.release' }

Write-Host 'Buscando releases no GitHub...' -ForegroundColor Cyan
$releases = gh api "repos/$Repo/releases" --paginate | ConvertFrom-Json
if (-not $releases) { throw 'Nenhuma release encontrada.' }

$headers = @{
    Authorization  = "Bearer $key"
    apikey         = $key
    'Content-Type' = 'application/json'
    Prefer         = 'resolution=merge-duplicates,return=minimal'
}

$count = 0
foreach ($rel in $releases) {
    $tag = $rel.tag_name -replace '^v', ''
    if (-not $tag) { continue }

    $build = Get-BuildFromVersion $tag
    # Builds reais do projeto: 1.0.x usa patch como build; 1.1+ segue pubspec (+5/+6)
    if ($tag -match '^1\.0\.') {
        $build = [int]($tag -split '\.')[2]
    } elseif ($tag -eq '1.1.0') { $build = 5 }
    elseif ($tag -eq '1.2.0') { $build = 6 }

    $body = if ($rel.body) { $rel.body.Trim() } else { '' }
    if (-not $body) { $body = "Atualização v$tag" }

    $payload = @{
        version     = $tag
        build       = $build
        changelog   = $body
        released_at = $rel.published_at
    } | ConvertTo-Json -Compress

    Invoke-RestMethod `
        -Uri "$baseUrl/rest/v1/app_version_history?on_conflict=version,build" `
        -Method Post -Headers $headers -Body $payload | Out-Null
    Write-Host "  v$tag (build $build)" -ForegroundColor Green
    $count++
}

Write-Host "Concluído: $count versão(ões) sincronizadas." -ForegroundColor Green
