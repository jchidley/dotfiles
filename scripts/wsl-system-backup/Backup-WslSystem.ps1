[CmdletBinding()]
param(
    [ValidateSet('Preflight', 'Export', 'Validate')]
    [string] $Mode = 'Preflight',
    [string] $Distro = 'Debian-Recovered',
    [string] $StagingDirectory = (Join-Path $env:USERPROFILE 'wsl-backup-staging\distro-exports'),
    [string] $ArchivePath,
    [switch] $ConfirmMaintenanceWindow,
    [switch] $SourceAlreadyStopped,
    [int64] $MinimumFreeBytes = 45GB
)

$ErrorActionPreference = 'Stop'
$wsl = Join-Path $env:SystemRoot 'System32\wsl.exe'
$validator = '/usr/local/sbin/validate-wsl-system-restore'
$temporaryValidator = '/tmp/validate-wsl-system-restore-current'
$resticTaskPattern = 'WSL Home Restic - *'

function Disable-ResticTasks {
    $tasks = @(Get-ScheduledTask -TaskName $resticTaskPattern -ErrorAction SilentlyContinue)
    if ($tasks.Count -ne 6) {
        throw "Expected six Restic tasks, found $($tasks.Count); refusing an uncoordinated export"
    }
    $running = @($tasks | Where-Object State -eq 'Running')
    if ($running.Count -gt 0) {
        throw "Restic tasks are currently running: $($running.TaskName -join ', ')"
    }
    $enabled = @($tasks | Where-Object State -ne 'Disabled' | Select-Object -ExpandProperty TaskName)
    $disabled = @()
    try {
        foreach ($taskName in $enabled) {
            Disable-ScheduledTask -TaskName $taskName | Out-Null
            $disabled += $taskName
        }
        $raced = @(Get-ScheduledTask -TaskName $resticTaskPattern | Where-Object State -eq 'Running')
        if ($raced.Count -gt 0) {
            throw "Restic tasks started during suspension: $($raced.TaskName -join ', ')"
        }
        return $disabled
    }
    catch {
        foreach ($taskName in $disabled) {
            Enable-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue | Out-Null
        }
        throw
    }
}

function Enable-ResticTasks {
    param([string[]] $TaskNames)
    foreach ($taskName in $TaskNames) {
        Enable-ScheduledTask -TaskName $taskName | Out-Null
    }
}

function Convert-ToWslPath {
    param([Parameter(Mandatory = $true)][string] $WindowsPath)
    $full = [IO.Path]::GetFullPath($WindowsPath)
    if ($full -notmatch '^([A-Za-z]):\\(.*)$') {
        throw "Validator source is not on a Windows drive: $full"
    }
    $drive = $Matches[1].ToLowerInvariant()
    $relative = $Matches[2].Replace('\', '/')
    return "/mnt/$drive/$relative"
}

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
    if ($SourceAlreadyStopped) {
        if (Test-DistroRunning $Distro) {
            throw "$Distro is running despite -SourceAlreadyStopped"
        }
        $validatorState = 'deferred; previously installed and source remains stopped'
    }
    else {
        Invoke-WslChecked @('-d', $Distro, '-u', 'root', '--', 'test', '-x', $validator)
        $validatorState = $validator
    }
    [pscustomobject]@{
        Distro = $Distro
        DistroRunning = (Test-DistroRunning $Distro)
        StagingDirectory = $StagingDirectory
        AvailableBytes = $free
        RequiredBytes = $MinimumFreeBytes
        Validator = $validatorState
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
        $hostValidator = Convert-ToWslPath (Join-Path $PSScriptRoot 'validate-wsl-system-restore')
        Invoke-WslChecked @('-d', $name, '-u', 'root', '--', 'install', '-o', 'root', '-g', 'root', '-m', '755', $hostValidator, $temporaryValidator)
        Invoke-WslChecked @('-d', $name, '-u', 'root', '--', $temporaryValidator)
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

$mutexName = 'Local\WSLSystemBackup-' + ($Distro -replace '[^A-Za-z0-9_.-]', '_')
$mutex = [Threading.Mutex]::new($false, $mutexName)
if (-not $mutex.WaitOne(0)) {
    $mutex.Dispose()
    throw "Another whole-system backup operation owns $mutexName"
}

$resticTasksDisabledByRun = @()
try {
if ($Mode -eq 'Validate') {
    if (-not $ArchivePath) { throw '-ArchivePath is required in Validate mode' }
    Test-ImportedArchive -Path $ArchivePath | Format-List
    return
}

if (-not $ConfirmMaintenanceWindow) {
    throw 'Export mode stops Debian-Recovered. Re-run with -ConfirmMaintenanceWindow during an approved maintenance window.'
}

Assert-Preflight | Out-Null
New-Item -ItemType Directory -Path $StagingDirectory -Force | Out-Null
$resticTasksDisabledByRun = @(Disable-ResticTasks)
if ($resticTasksDisabledByRun.Count -gt 0) {
    Write-Output "Temporarily disabled Restic tasks: $($resticTasksDisabledByRun -join ', ')"
}
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$baseName = "${timestamp}_${Distro}"
$partial = Join-Path $StagingDirectory "$baseName.tar.gz.partial"
$final = Join-Path $StagingDirectory "$baseName.tar.gz"
$manifest = "$final.manifest.json"
if ((Test-Path -LiteralPath $partial) -or (Test-Path -LiteralPath $final)) {
    throw "Refusing to replace an existing generation: $baseName"
}

$wasRunning = Test-DistroRunning $Distro
if ($SourceAlreadyStopped -and $wasRunning) {
    throw "$Distro started after preflight; refusing the stopped-source export"
}
$exportCompleted = $false
$promoted = $false
try {
    if ($wasRunning) {
        Invoke-WslChecked @('-d', $Distro, '-u', 'root', '--', 'sync')
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
    $promoted = $true
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
    if ($promoted -and (Test-Path -LiteralPath $final)) {
        Move-Item -LiteralPath $final -Destination ($final + '.failed') -Force
    }
    Remove-Item -LiteralPath ($manifest + '.partial') -Force -ErrorAction SilentlyContinue
    throw
}
}
finally {
    try {
        if ($resticTasksDisabledByRun.Count -gt 0) {
            Enable-ResticTasks -TaskNames $resticTasksDisabledByRun
            Write-Output "Restored Restic tasks: $($resticTasksDisabledByRun -join ', ')"
        }
    }
    finally {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
}
