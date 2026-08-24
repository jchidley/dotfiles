#requires -Version 7.0
# GPG-backed API-key integration for PowerShell 7.
# The calling profile sets AkVaultConfig, AkExportProfile, AkVaultPath, and
# AkWslDistro before importing this file.

function Initialize-AkVault {
    if ($script:AkWslDistro) { return }
    if (-not (Test-Path $script:AkVaultConfig)) {
        throw "ak vault config not found: $script:AkVaultConfig"
    }

    $entries = @(Get-Content $script:AkVaultConfig | Where-Object { $_ -match '^wsl_distro=' })
    if ($entries.Count -ne 1) {
        throw "Expected exactly one wsl_distro entry in $script:AkVaultConfig"
    }

    $distro = ($entries[0] -replace '^wsl_distro=', '').Trim()
    if ($distro -notmatch '^[A-Za-z0-9._-]+$') {
        throw "Invalid wsl_distro in $script:AkVaultConfig"
    }
    $script:AkWslDistro = $distro
}

function Invoke-AkVault {
    param(
        [string[]]$AkArguments,
        [switch]$Quiet
    )
    Initialize-AkVault
    if ($Quiet) {
        $output = & wsl.exe -d $script:AkWslDistro --exec $script:AkVaultPath @AkArguments 2>$null
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "ak failed in WSL distro '$script:AkWslDistro' (exit $exitCode)"
        }
        return $output
    }

    & wsl.exe -d $script:AkWslDistro --exec $script:AkVaultPath @AkArguments
    if ($LASTEXITCODE -ne 0) {
        throw "ak failed in WSL distro '$script:AkWslDistro' (exit $LASTEXITCODE)"
    }
}

function ak-get {
    param([Parameter(Mandatory = $true)][string]$Service)
    if ($Service -notmatch '^[A-Za-z0-9._-]+$') { throw "Invalid ak service: $Service" }
    Invoke-AkVault @('get', $Service)
}
function ak-set {
    param([Parameter(Mandatory = $true)][string]$Service)
    if ($Service -notmatch '^[A-Za-z0-9._-]+$') { throw "Invalid ak service: $Service" }
    Invoke-AkVault @('set', $Service)
}
function ak-list { Invoke-AkVault @('list') }

function Import-AkExportProfile {
    if (-not (Test-Path $script:AkExportProfile)) { return }

    $services = [System.Collections.Generic.List[string]]::new()
    foreach ($rawLine in Get-Content $script:AkExportProfile) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith('#')) { continue }
        if ($line -notmatch '^use_ak(?:\s+[A-Za-z0-9._-]+)+$') {
            throw "Invalid ak export profile line: $line"
        }
        foreach ($service in ($line -split '\s+' | Select-Object -Skip 1)) {
            if (-not $services.Contains($service)) { $services.Add($service) }
        }
    }

    # Resolve before mutating the environment. Invalid/non-exportable profile
    # entries fail closed; exportable services whose encrypted value is absent
    # are reported and skipped so a partially restored vault remains usable.
    $resolved = @{}
    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($service in $services) {
        $envVar = ((Invoke-AkVault @('env-var', $service)) -join "`n").Trim()
        if ($envVar -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
            throw "Invalid environment variable returned for ak service '$service'"
        }
        try {
            $value = (Invoke-AkVault -AkArguments @('get', $service) -Quiet) -join "`n"
            $resolved[$envVar] = $value
        } catch {
            $missing.Add($service)
        }
    }
    if ($missing.Count -gt 0) {
        Write-Warning "ak export profile skipped unavailable services: $($missing -join ', ')"
    }
    foreach ($entry in $resolved.GetEnumerator()) {
        Set-Item -Path "Env:$($entry.Key)" -Value $entry.Value
    }
}
