[CmdletBinding()]
param(
    [ValidateSet('Preflight', 'Export', 'Validate')]
    [string] $Mode = 'Preflight',
    [string] $Distro = 'Debian-Recovered',
    [string] $StagingDirectory = (Join-Path $env:USERPROFILE 'wsl-backup-staging\distro-exports'),
    [string] $ArchivePath,
    [switch] $ConfirmMaintenanceWindow,
    [int64] $MinimumFreeBytes = 45GB
)

$ErrorActionPreference = 'Stop'
$wsl = Join-Path $env:SystemRoot 'System32\wsl.exe'
$validator = '/usr/local/sbin/validate-wsl-system-restore'

function Invoke-WslChecked {
    param([Parameter(Mandatory = $true)][string[]] $Arguments)
    & $wsl @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "wsl.exe failed with exit code ${LASTEXITCODE}: $($Arguments -join ' ')"
    }
}

function Get-DistroNames {
    @(& $wsl --list --quiet) | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ }
}

function Test-DistroRunning {
    param([string] $Name)
    $running = @(& $wsl --list --running --quiet) | ForEach-Object { ($_ -replace "`0", '').Trim() }
    return $running -contains $Name
}

function Assert-Preflight {
    $distros = @(Get-DistroNames)
    if ($distros -notcontains $Distro) {
        throw "Expected WSL distro is not registered: $Distro"
    }
    $root = [IO.Path]::GetPathRoot([IO.Path]::GetFullPath($StagingDirectory))
    $free = ([IO.DriveInfo]::new($root)).AvailableFreeSpace
    if ($free -lt $MinimumFreeBytes) {
        throw "Insufficient free space on ${root}: $free bytes; require $MinimumFreeBytes"
    }
    Invoke-WslChecked @('-d', $Distro, '-u', 'root', '--', 'test', '-x', $validator)
    [pscustomobject]@{
        Distro = $Distro
        DistroRunning = (Test-DistroRunning $Distro)
        StagingDirectory = $StagingDirectory
        AvailableBytes = $free
        RequiredBytes = $MinimumFreeBytes
        Validator = $validator
    }
}

function Test-ImportedArchive {
    param([Parameter(Mandatory = $true)][string] $Path)
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $name = 'Debian-backup-validation-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
    $directory = Join-Path $env:LOCALAPPDATA "WSLSystemBackupValidation\$name"
    $registered = $false
    try {
        New-Item -ItemType Directory -Path (Split-Path -Parent $directory) -Force | Out-Null
        Invoke-WslChecked @('--import', $name, $directory, $resolved, '--version', '2')
        $registered = $true
        Invoke-WslChecked @('--manage', $name, '--set-default-user', 'jack')
        Invoke-WslChecked @('-d', $name, '-u', 'root', '--', $validator)
        return [pscustomobject]@{
            Result = 'passed'
            ValidatedAt = (Get-Date).ToUniversalTime().ToString('o')
            DisposableDistro = $name
        }
    }
    finally {
        if ($registered) {
            & $wsl --unregister $name | Out-Null
        }
        if (Test-Path -LiteralPath $directory) {
            Remove-Item -LiteralPath $directory -Recurse -Force
        }
    }
}

if ($Mode -eq 'Preflight') {
    Assert-Preflight | Format-List
    exit 0
}

if ($Mode -eq 'Validate') {
    if (-not $ArchivePath) { throw '-ArchivePath is required in Validate mode' }
    Test-ImportedArchive -Path $ArchivePath | Format-List
    exit 0
}

if (-not $ConfirmMaintenanceWindow) {
    throw 'Export mode stops Debian-Recovered. Re-run with -ConfirmMaintenanceWindow during an approved maintenance window.'
}

Assert-Preflight | Out-Null
New-Item -ItemType Directory -Path $StagingDirectory -Force | Out-Null
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$baseName = "${timestamp}_${Distro}"
$partial = Join-Path $StagingDirectory "$baseName.tar.gz.partial"
$final = Join-Path $StagingDirectory "$baseName.tar.gz"
$manifest = "$final.manifest.json"
if ((Test-Path -LiteralPath $partial) -or (Test-Path -LiteralPath $final)) {
    throw "Refusing to replace an existing generation: $baseName"
}

$wasRunning = Test-DistroRunning $Distro
$exportCompleted = $false
try {
    Invoke-WslChecked @('-d', $Distro, '-u', 'root', '--', 'sync')
    if (Test-DistroRunning $Distro) {
        Invoke-WslChecked @('--terminate', $Distro)
    }
    try {
        Invoke-WslChecked @('--export', $Distro, $partial, '--format', 'tar.gz')
        $exportCompleted = $true
    }
    finally {
        if ($wasRunning) {
            Invoke-WslChecked @('-d', $Distro, '-u', 'root', '--', 'true')
        }
    }

    $hash = (Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash.ToLowerInvariant()
    $validation = Test-ImportedArchive -Path $partial
    Move-Item -LiteralPath $partial -Destination $final
    $archive = Get-Item -LiteralPath $final
    $record = [ordered]@{
        SchemaVersion = 1
        Distro = $Distro
        CreatedAt = (Get-Date).ToUniversalTime().ToString('o')
        Archive = $archive.Name
        ArchiveBytes = $archive.Length
        Sha256 = $hash
        Format = 'tar.gz'
        Validation = $validation
        WslVersion = ((& $wsl --version | Out-String).Trim())
    }
    $manifestTemp = "$manifest.partial"
    $record | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestTemp -Encoding UTF8
    Move-Item -LiteralPath $manifestTemp -Destination $manifest

    $generations = @(Get-ChildItem -LiteralPath $StagingDirectory -Filter "*_${Distro}.tar.gz" -File |
        Sort-Object Name -Descending)
    foreach ($old in @($generations | Select-Object -Skip 2)) {
        Remove-Item -LiteralPath $old.FullName -Force
        Remove-Item -LiteralPath ($old.FullName + '.manifest.json') -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Validated system generation: $final"
    Write-Output "SHA-256: $hash"
}
catch {
    if ($exportCompleted -and (Test-Path -LiteralPath $partial)) {
        Move-Item -LiteralPath $partial -Destination ($partial + '.failed') -Force
    }
    throw
}
