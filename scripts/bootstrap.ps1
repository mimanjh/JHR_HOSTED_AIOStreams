[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https://[A-Za-z0-9.-]+(?::[0-9]+)?$')]
    [string]$BaseUrl
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$envTemplatePath = Join-Path $projectRoot '.env.example'
$envPath = Join-Path $projectRoot '.env'
$secretsDirectory = Join-Path $projectRoot 'secrets'
$tokenTemplatePath = Join-Path $secretsDirectory 'cloudflare-tunnel-token.txt.example'
$tokenPath = Join-Path $secretsDirectory 'cloudflare-tunnel-token.txt'

if (Test-Path -LiteralPath $envPath) {
    throw "Refusing to overwrite existing local configuration: $envPath"
}

if (-not (Test-Path -LiteralPath $envTemplatePath)) {
    throw "Missing template: $envTemplatePath"
}

function New-RandomHex {
    param([Parameter(Mandatory = $true)][int]$ByteCount)

    $bytes = New-Object byte[] $ByteCount
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    }
    finally {
        $rng.Dispose()
    }

    return [BitConverter]::ToString($bytes).Replace('-', '').ToLowerInvariant()
}

$secretKey = New-RandomHex -ByteCount 32
$adminPassword = New-RandomHex -ByteCount 24
$environment = Get-Content -LiteralPath $envTemplatePath -Raw
$environment = $environment.Replace('https://aio.example.com', $BaseUrl.TrimEnd('/'))
$environment = $environment.Replace('replace_with_a_64_character_hex_string', $secretKey)
$environment = $environment.Replace('admin:replace_with_a_strong_password', "admin:$adminPassword")

$utf8WithoutBom = New-Object Text.UTF8Encoding $false
[IO.File]::WriteAllText($envPath, $environment, $utf8WithoutBom)

New-Item -ItemType Directory -Path $secretsDirectory -Force | Out-Null

if (-not (Test-Path -LiteralPath $tokenPath)) {
    Copy-Item -LiteralPath $tokenTemplatePath -Destination $tokenPath
}

Write-Host 'Created ignored local configuration files.'
Write-Host "Base URL: $($BaseUrl.TrimEnd('/'))"
Write-Host 'A random SECRET_KEY and operator password were written to .env.'
Write-Host 'Generated credentials were not printed. Open .env locally when needed.'
Write-Host 'Next: replace the placeholder in secrets/cloudflare-tunnel-token.txt.'
