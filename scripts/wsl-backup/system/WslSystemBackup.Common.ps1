#requires -Version 7.0
Set-StrictMode -Version Latest

function Write-AtomicJson {
    param([Parameter(Mandatory)]$Value, [Parameter(Mandatory)][string]$Path, [int]$Depth = 8)
    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $temporary = "$Path.$([guid]::NewGuid().ToString('N')).partial"
    try {
        $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $temporary -Encoding utf8NoBOM
        [IO.File]::Move($temporary, $Path, $true)
    }
    finally {
        Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
    }
}

function Read-CombinedBackupConfig {
    param([Parameter(Mandatory)][string]$Path)
    try { $config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
    catch { throw "Combined-backup configuration is unreadable: $($_.Exception.Message)" }
    if ($config.schemaVersion -ne 1 -or $config.distro -ne 'Debian4') { throw 'Combined-backup configuration identity is invalid' }
    foreach ($property in 'targetLabel','diskGuid','volumeId','fileSystem','systemRelativePath','homeRepositoryRelativePath','sourceRepositoryId','externalRepositoryId') {
        if ([string]::IsNullOrWhiteSpace([string]$config.$property)) { throw "Combined-backup configuration is missing: $property" }
    }
    if ([guid]::Empty -eq [guid]$config.diskGuid) { throw 'Configured disk GUID is invalid' }
    if ($config.sourceRepositoryId -notmatch '^[0-9a-f]{64}$' -or $config.externalRepositoryId -notmatch '^[0-9a-f]{64}$') {
        throw 'Configured Restic repository ID is invalid'
    }
    foreach ($relative in $config.systemRelativePath, $config.homeRepositoryRelativePath) {
        if ([IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') { throw "Configured target path is unsafe: $relative" }
    }
    return $config
}

function Resolve-CombinedBackupTarget {
    param(
        [Parameter(Mandatory)]$Config,
        [scriptblock]$GetVolumes = { @(Get-Volume) },
        [scriptblock]$GetPartitions = { param($volume) @(Get-Partition -Volume $volume) },
        [scriptblock]$GetDisks = { param($partition) @($partition | Get-Disk) }
    )
    $volumes = @(& $GetVolumes | Where-Object UniqueId -eq $Config.volumeId)
    if ($volumes.Count -ne 1) { throw "Expected target volume is absent or ambiguous: $($Config.targetLabel)" }
    $volume = $volumes[0]
    if ($volume.FileSystemLabel -ne $Config.targetLabel -or $volume.FileSystem -ne $Config.fileSystem) {
        throw 'Target volume label or filesystem mismatch'
    }
    $partitions = @(& $GetPartitions $volume)
    if ($partitions.Count -ne 1) { throw 'Target volume partition is ambiguous' }
    $disks = @(& $GetDisks $partitions[0])
    if ($disks.Count -ne 1 -or [guid]$disks[0].Guid -ne [guid]$Config.diskGuid -or $disks[0].BusType -ne 'USB' -or $disks[0].IsOffline) {
        throw 'Target physical-disk identity or availability mismatch'
    }
    if ($volume.DriveLetter -notmatch '^[A-Z]$') { throw 'Verified target has no drive-letter transport' }
    $root = "$($volume.DriveLetter):\"
    [pscustomobject]@{ Root=$root; FreeBytes=[int64]$volume.SizeRemaining; VolumeId=$volume.UniqueId; DiskGuid=[string]$disks[0].Guid }
}

function Assert-SafeTargetPath {
    param([Parameter(Mandatory)][string]$VolumeRoot, [Parameter(Mandatory)][string]$RelativePath)
    $root = [IO.Path]::GetFullPath($VolumeRoot).TrimEnd('\') + '\'
    $candidate = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
    if (-not $candidate.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw 'Target path escapes the verified volume' }
    $current = $root.TrimEnd('\')
    foreach ($component in ($RelativePath -split '[\\/]' | Where-Object { $_ })) {
        $current = Join-Path $current $component
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw "Unsafe target component: $current"
            }
        }
    }
    return $candidate
}

function Complete-CombinedGeneration {
    param([Parameter(Mandatory)][string]$PartialDirectory, [Parameter(Mandatory)][string]$FinalDirectory)
    if (Test-Path -LiteralPath $FinalDirectory) { throw 'Refusing to replace a completed generation' }
    $manifest = Join-Path $PartialDirectory 'manifest.json'
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf) -or (Get-Item -LiteralPath $manifest).Length -eq 0) {
        throw 'Partial generation is not promotable: manifest.json'
    }
    Move-Item -LiteralPath $PartialDirectory -Destination $FinalDirectory
}

function Convert-ToWslDrivePath {
    param([Parameter(Mandatory)][string]$WindowsPath)
    $full = [IO.Path]::GetFullPath($WindowsPath)
    if ($full -notmatch '^([A-Za-z]):\\(.*)$') { throw 'Only a local drive path can cross into WSL' }
    "/mnt/$($Matches[1].ToLowerInvariant())/$($Matches[2].Replace('\','/'))"
}
