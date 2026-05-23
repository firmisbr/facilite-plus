#Requires -Version 5.1
<#
.SYNOPSIS
  Build release APK, cria GitHub Release, envia APK e atualiza app_update_manifest no Supabase.

.EXAMPLE
  .\scripts\release.ps1 -Bump patch -Changelog "Correções na sync"

.EXAMPLE
  .\scripts\release.ps1 -Version 1.2.0 -Changelog "Nova tela de relatórios"

.EXAMPLE
  # Só upload (APK já buildado, versão já bumped):
  .\scripts\release.ps1 -SkipVersionBump -SkipBuild -Changelog "Reenvio"

  Configure antes: copie .env.release.example → .env.release
#>
param(
    [ValidateSet('patch', 'minor', 'major')]
    [string] $Bump,

    [string] $Version,
    [string] $Changelog = '',
    [switch] $SkipBuild,
    [switch] $SkipUpload,
    [switch] $SkipVersionBump,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

function Write-Step([string]$msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "    $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "    $msg" -ForegroundColor Yellow }

# ─── .env.release ────────────────────────────────────────────────────────────

function Load-EnvFile([string]$path) {
    if (-not (Test-Path $path)) {
        throw "Arquivo $path não encontrado. Copie .env.release.example para .env.release e preencha."
    }
    Get-Content $path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }
        $i = $line.IndexOf('=')
        if ($i -lt 1) { return }
        $name  = $line.Substring(0, $i).Trim()
        $value = $line.Substring($i + 1).Trim().Trim('"').Trim("'")
        [Environment]::SetEnvironmentVariable($name, $value, 'Process')
    }
}

# ─── Versão ───────────────────────────────────────────────────────────────────

function Get-CurrentVersion {
    $pubspec = Get-Content 'pubspec.yaml' -Raw
    if ($pubspec -notmatch 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
        throw "pubspec.yaml: version inválida. Use formato X.Y.Z+BUILD (ex: 1.0.0+1)."
    }
    return @{ Major=[int]$Matches[1]; Minor=[int]$Matches[2]; Patch=[int]$Matches[3]; Build=[int]$Matches[4] }
}

function Resolve-NextVersion($current) {
    $m = $current.Major; $n = $current.Minor; $p = $current.Patch; $b = $current.Build + 1

    if ($Version) {
        if ($Version -notmatch '^(\d+)\.(\d+)\.(\d+)$') { throw "Version deve ser X.Y.Z (ex: 1.0.1)" }
        return @{ Major=[int]$Matches[1]; Minor=[int]$Matches[2]; Patch=[int]$Matches[3]; Build=$b }
    }

    if (-not $Bump) { throw "Informe -Bump patch|minor|major ou -Version X.Y.Z" }

    switch ($Bump) {
        'patch' { $p++ }
        'minor' { $n++; $p = 0 }
        'major' { $m++; $n = 0; $p = 0 }
    }
    return @{ Major=$m; Minor=$n; Patch=$p; Build=$b }
}

function Set-ProjectVersion($v) {
    $semver = "$($v.Major).$($v.Minor).$($v.Patch)"
    $full   = "$semver+$($v.Build)"

    $pub = Get-Content 'pubspec.yaml' -Raw
    $pub = $pub -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $full"
    Set-Content -Path 'pubspec.yaml' -Value $pub.TrimEnd() -Encoding utf8
    Write-Ok "pubspec.yaml → $full"

    $av = Get-Content 'lib/core/config/app_version.dart' -Raw
    $av = $av -replace "static const fallback = '[^']+';", "static const fallback = '$semver';"
    Set-Content -Path 'lib/core/config/app_version.dart' -Value $av.TrimEnd() -Encoding utf8
    Write-Ok "app_version.dart fallback → $semver"
}

# ─── Build ────────────────────────────────────────────────────────────────────

function Get-ReleaseApkPath {
    $path = Join-Path $root 'build/app/outputs/flutter-apk/app-release.apk'
    if (Test-Path $path) { return $path }
    throw "APK não encontrado: $path`nRode sem -SkipBuild."
}

function Invoke-FlutterBuild {
    Write-Step 'Flutter: pub get + build apk --release'
    & flutter pub get 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get falhou' }

    Write-Ok 'APK universal (todas as arquiteturas)'
    & flutter build apk --release 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw 'flutter build apk falhou' }

    return ,(Get-ReleaseApkPath)
}

# ─── GitHub Release ───────────────────────────────────────────────────────────

function Send-GitHubRelease {
    param($v, $apkPath, $changelogText)

    $repo    = [Environment]::GetEnvironmentVariable('GITHUB_REPO')    # ex: firmisbr/facilite-plus
    $token   = [Environment]::GetEnvironmentVariable('GITHUB_TOKEN')
    $semver  = "$($v.Major).$($v.Minor).$($v.Patch)"
    $tagName = "v$semver"
    $apkName = "facilite-plus-$semver.apk"

    if (-not $repo)  { throw "GITHUB_REPO ausente em .env.release (ex: firmisbr/facilite-plus)" }
    if (-not $token) { throw "GITHUB_TOKEN ausente em .env.release" }

    $apiBase = "https://api.github.com/repos/$repo"
    $ghHeaders = @{
        Authorization = "Bearer $token"
        Accept        = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    # Verificar se release já existe para a tag e deletar (upsert)
    Write-Step "GitHub Release: $tagName"
    try {
        $existing = Invoke-RestMethod -Uri "$apiBase/releases/tags/$tagName" -Headers $ghHeaders -ErrorAction Stop
        Write-Warn "Release $tagName já existe — removendo para recriar..."
        Invoke-RestMethod -Uri "$apiBase/releases/$($existing.id)" -Method Delete -Headers $ghHeaders | Out-Null
    } catch {
        # Não existe, tudo bem
    }

    if ($DryRun) {
        Write-Warn "[DryRun] Criaria release $tagName no GitHub"
        return "https://github.com/$repo/releases/download/$tagName/$apkName"
    }

    # Criar a release
    $releaseBody = @{
        tag_name         = $tagName
        name             = "Facilite Plus $semver"
        body             = $changelogText
        draft            = $false
        prerelease       = $false
        target_commitish = 'main'
    } | ConvertTo-Json -Compress

    $release = Invoke-RestMethod -Uri "$apiBase/releases" -Method Post `
        -Headers ($ghHeaders + @{ 'Content-Type' = 'application/json' }) `
        -Body $releaseBody
    Write-Ok "Release criada: $($release.html_url)"

    # Upload do APK como asset
    $uploadUrl = $release.upload_url -replace '\{\?name,label\}', "?name=$apkName"
    $uploadHeaders = $ghHeaders.Clone()
    $uploadHeaders['Content-Type'] = 'application/vnd.android.package-archive'

    Write-Step "Upload APK: $apkName ($([math]::Round((Get-Item -LiteralPath $apkPath).Length / 1MB, 2)) MB)"
    $bytes = [System.IO.File]::ReadAllBytes($apkPath)
    Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -Body $bytes | Out-Null
    Write-Ok 'APK enviado'

    $downloadUrl = "https://github.com/$repo/releases/download/$tagName/$apkName"
    Write-Ok "Download URL: $downloadUrl"

    return $downloadUrl
}

# ─── Supabase manifest ────────────────────────────────────────────────────────

function Update-SupabaseManifest {
    param($v, $apkUrl, $changelogText)

    $baseUrl = [Environment]::GetEnvironmentVariable('SUPABASE_URL').TrimEnd('/')
    $key     = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_ROLE_KEY')
    $semver  = "$($v.Major).$($v.Minor).$($v.Patch)"

    if (-not $baseUrl) { throw "SUPABASE_URL ausente em .env.release" }
    if (-not $key)     { throw "SUPABASE_SERVICE_ROLE_KEY ausente em .env.release" }

    Write-Step 'Atualizar app_update_manifest no Supabase (id=1)'

    $headers = @{
        Authorization  = "Bearer $key"
        apikey         = $key
        'Content-Type' = 'application/json'
        Prefer         = 'return=minimal'
    }

    $body = @{
        version    = $semver
        build      = $v.Build
        apk_url    = $apkUrl
        changelog  = $changelogText
        updated_at = (Get-Date).ToUniversalTime().ToString('o')
    } | ConvertTo-Json -Compress

    if ($DryRun) {
        Write-Warn "[DryRun] PATCH $baseUrl/rest/v1/app_update_manifest?id=eq.1"
        Write-Warn $body
    } else {
        Invoke-RestMethod -Uri "$baseUrl/rest/v1/app_update_manifest?id=eq.1" `
            -Method Patch -Headers $headers -Body $body | Out-Null
        Write-Ok "Manifesto → v$semver (build $($v.Build))"
    }
}

# ─── Main ─────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host '  Facilite Plus — Release OTA' -ForegroundColor White
Write-Host '  ───────────────────────────' -ForegroundColor DarkGray

Load-EnvFile (Join-Path $root '.env.release')

$current = Get-CurrentVersion

if ($SkipVersionBump) {
    $next = $current
    Write-Warn "`nSkipVersionBump: mantendo versão $($current.Major).$($current.Minor).$($current.Patch)+$($current.Build)"
} else {
    $next = Resolve-NextVersion $current
}

$semver = "$($next.Major).$($next.Minor).$($next.Patch)"
if (-not $Changelog) { $Changelog = "Atualização v$semver" }

Write-Step "Versão: $($current.Major).$($current.Minor).$($current.Patch)+$($current.Build) → $semver+$($next.Build)"
if ($DryRun) { Write-Warn 'Modo DryRun ativo' }

if (-not $SkipVersionBump) { Set-ProjectVersion $next }

$apk = $null
if (-not $SkipBuild) {
    $apk = Invoke-FlutterBuild
    if ($apk -is [array]) { $apk = $apk[-1] }
    Write-Ok "APK: $apk ($([math]::Round((Get-Item -LiteralPath $apk).Length / 1MB, 2)) MB)"
} else {
    $apk = Get-ReleaseApkPath
    Write-Ok "SkipBuild: usando $apk ($([math]::Round((Get-Item -LiteralPath $apk).Length / 1MB, 2)) MB)"
}

if (-not $SkipUpload) {
    $apkUrl = Send-GitHubRelease -v $next -apkPath $apk -changelogText $Changelog
    Update-SupabaseManifest -v $next -apkUrl $apkUrl -changelogText $Changelog

    Write-Host ''
    Write-Host '  Release concluída!' -ForegroundColor Green
    Write-Host "  APK:      $apkUrl" -ForegroundColor DarkGray
    Write-Host "  Usuários com versão antiga verão a bolinha amarela em Config." -ForegroundColor DarkGray
} else {
    Write-Warn 'SkipUpload: GitHub e manifesto não foram atualizados.'
}

Write-Host ''
