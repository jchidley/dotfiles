#requires -Version 7.0
$ErrorActionPreference = 'Stop'

$testDir = if ($env:DOTFILES_TEST_DIR) { $env:DOTFILES_TEST_DIR } else { $PSScriptRoot }
$repoRoot = if ($env:DOTFILES_REPO_ROOT) {
    $env:DOTFILES_REPO_ROOT
} else {
    (Resolve-Path (Join-Path $testDir '..\..')).Path
}
$modulePath = Join-Path $repoRoot 'Documents\PowerShell\ak-profile.ps1'
$work = Join-Path $env:TEMP ('powershell-ak-profile-test-' + [guid]::NewGuid().ToString('N'))

function Assert-Equal($Actual, $Expected, [string]$Message) {
    if ($Actual -ne $Expected) {
        throw "$Message (expected '$Expected', got '$Actual')"
    }
}

function Assert-True($Value, [string]$Message) {
    if (-not $Value) { throw $Message }
}

function Assert-Throws([scriptblock]$Action, [string]$Pattern, [string]$Message) {
    try {
        & $Action
    } catch {
        if ($_.Exception.Message -notmatch $Pattern) {
            throw "$Message (unexpected error: $($_.Exception.Message))"
        }
        return
    }
    throw "$Message (no error was raised)"
}

try {
    $null = New-Item -ItemType Directory -Path $work
    . $modulePath

    # The nominated distro is mandatory, unique, and validated.
    $script:AkVaultConfig = Join-Path $work 'vault.conf'
    $script:AkWslDistro = $null
    Set-Content -LiteralPath $script:AkVaultConfig -Value "wsl_distro=Debian-Recovered`n"
    Initialize-AkVault
    Assert-Equal $script:AkWslDistro 'Debian-Recovered' 'named WSL distro was not loaded'

    $script:AkWslDistro = $null
    Set-Content -LiteralPath $script:AkVaultConfig -Value "wsl_distro=Debian`nwsl_distro=Ubuntu`n"
    Assert-Throws { Initialize-AkVault } 'exactly one' 'duplicate distro nomination did not fail closed'

    $script:AkWslDistro = $null
    Set-Content -LiteralPath $script:AkVaultConfig -Value "wsl_distro=Debian;bad`n"
    Assert-Throws { Initialize-AkVault } 'Invalid wsl_distro' 'unsafe distro nomination was accepted'

    # Replace transport with a deterministic fake. No real secrets are read.
    $values = @{ alpha = 'fake-alpha-value'; beta = 'fake-beta-value' }
    $envVars = @{ alpha = 'TEST_AK_ALPHA'; beta = 'TEST_AK_BETA'; missing = 'TEST_AK_MISSING' }
    $calls = [System.Collections.Generic.List[string]]::new()
    function Invoke-AkVault {
        param([string[]]$AkArguments, [switch]$Quiet)
        $calls.Add(($AkArguments -join ':'))
        if ($AkArguments[0] -eq 'env-var') {
            if ($AkArguments[1] -eq 'private') { throw 'service is not exportable' }
            return $envVars[$AkArguments[1]]
        }
        if ($AkArguments[0] -eq 'get') {
            if (-not $values.ContainsKey($AkArguments[1])) { throw 'secret unavailable' }
            return $values[$AkArguments[1]]
        }
        throw 'unexpected fake ak operation'
    }

    foreach ($name in 'TEST_AK_ALPHA', 'TEST_AK_BETA', 'TEST_AK_MISSING') {
        Remove-Item "Env:$name" -ErrorAction SilentlyContinue
    }

    $script:AkExportProfile = Join-Path $work '.envrc'
    Set-Content -LiteralPath $script:AkExportProfile -Value @(
        '# reviewed services'
        'use_ak alpha missing alpha'
        'use_ak beta'
    )
    $warningOutput = @(Import-AkExportProfile 3>&1)
    Assert-Equal $env:TEST_AK_ALPHA 'fake-alpha-value' 'available alpha secret was not imported'
    Assert-Equal $env:TEST_AK_BETA 'fake-beta-value' 'available beta secret was not imported'
    Assert-True (-not (Test-Path Env:TEST_AK_MISSING)) 'missing secret created an environment variable'
    Assert-True (($warningOutput -join "`n") -match 'missing') 'missing service was not summarized'
    Assert-Equal @($calls | Where-Object { $_ -eq 'get:alpha' }).Count 1 'duplicate service was resolved more than once'

    # Invalid profile syntax is rejected before any environment mutation.
    Remove-Item Env:TEST_AK_ALPHA -ErrorAction SilentlyContinue
    Set-Content -LiteralPath $script:AkExportProfile -Value @('use_ak alpha', 'export BAD=value')
    Assert-Throws { Import-AkExportProfile } 'Invalid ak export profile line' 'shell syntax in profile was accepted'
    Assert-True (-not (Test-Path Env:TEST_AK_ALPHA)) 'invalid profile partially mutated the environment'

    # A non-exportable/invalid service fails the whole profile before mutation.
    Set-Content -LiteralPath $script:AkExportProfile -Value 'use_ak alpha private'
    Assert-Throws { Import-AkExportProfile } 'not exportable' 'non-exportable service did not fail closed'
    Assert-True (-not (Test-Path Env:TEST_AK_ALPHA)) 'non-exportable profile partially mutated the environment'

    Write-Host 'PASS: PowerShell ak profile validates nomination and imports only its reviewed allowlist'
} finally {
    foreach ($name in 'TEST_AK_ALPHA', 'TEST_AK_BETA', 'TEST_AK_MISSING') {
        Remove-Item "Env:$name" -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
