[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot

try {
    if (-not (Test-Path -LiteralPath '.git')) {
        throw 'This safety check must run inside a Git repository.'
    }

    $trackedPaths = @(git ls-files --cached --others --exclude-standard)
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to enumerate tracked files.'
    }

    $forbiddenPaths = @(
        $trackedPaths | Where-Object {
            $_ -eq '.env' -or
            ($_ -like '.env.*' -and $_ -ne '.env.example') -or
            $_ -like 'data/*' -or
            ($_ -like 'secrets/*' -and $_ -notlike 'secrets/*.example') -or
            $_ -like 'backups/*' -or
            $_ -match '(?i)\.sqlite(?:-shm|-wal)?$'
        }
    )

    if ($forbiddenPaths.Count -gt 0) {
        throw "Forbidden tracked paths detected: $($forbiddenPaths -join ', ')"
    }

    $patterns = [ordered]@{
        GitHubToken = 'gh[opsu]_[A-Za-z0-9]{20,}'
        CloudflareTunnelToken = 'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}'
        PrivateKey = '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'
        PrivateManifestPath = '(?i)/stremio/[0-9a-f-]{20,}/[^/\s"'']{20,}'
        PersonalDeploymentHostname = '(?i)dongley\.app'
    }

    foreach ($path in $trackedPaths) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            continue
        }

        $content = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) {
            continue
        }

        foreach ($entry in $patterns.GetEnumerator()) {
            if ($content -match $entry.Value) {
                throw "Credential or deployment-specific pattern '$($entry.Key)' detected in: $path"
            }
        }
    }

    $example = Get-Content -LiteralPath '.env.example' -Raw
    if ($example -notmatch 'BASE_URL=https://aio\.example\.com') {
        throw '.env.example must use the reserved example hostname.'
    }
    if ($example -notmatch 'SECRET_KEY=replace_with_a_64_character_hex_string') {
        throw '.env.example must contain the SECRET_KEY placeholder.'
    }
    if ($example -notmatch 'AIOSTREAMS_AUTH=admin:replace_with_a_strong_password') {
        throw '.env.example must contain the operator-password placeholder.'
    }

    $dockerIgnore = Get-Content -LiteralPath '.dockerignore' -Raw
    foreach ($requiredRule in @('*', '!Dockerfile', '!docker/', '!docker/patch-request-limit.cjs')) {
        if (($dockerIgnore -split '\r?\n') -notcontains $requiredRule) {
            throw ".dockerignore is missing required allowlist rule: $requiredRule"
        }
    }

    Write-Host 'Repository safety checks passed.'
}
finally {
    Pop-Location
}
