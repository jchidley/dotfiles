#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$Distro = 'Debian4',
    [string]$OutputDirectory = 'C:\WSL-Backups\Debian4\full',
    [Parameter(Mandatory)]
    [string]$ExpectedVolumeUniqueId,
    [Parameter(Mandatory)]
    [string]$ExpectedDiskUniqueId
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-WslNames([switch]$Running) {
    $arguments = @('--list', '--quiet')
    if ($Running) { $arguments = @('--list', '--running', '--quiet') }
    $lines = @(& wsl.exe @arguments)
    if ($LASTEXITCODE -ne 0) { throw 'WSL inventory failed' }
    @($lines | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
}

function Get-DistroVhdPath([string]$Name) {
    $entries = @(Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' | ForEach-Object {
        Get-ItemProperty -LiteralPath $_.PSPath
    } | Where-Object DistributionName -EQ $Name)
    if ($entries.Count -ne 1) { throw 'Could not resolve one registered source distro storage path' }
    $path = [IO.Path]::GetFullPath((Join-Path $entries[0].BasePath 'ext4.vhdx'))
    $item = Get-Item -LiteralPath $path -Force
    if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw 'Source VHDX is redirected or is not a regular file'
    }
    $path
}

function Copy-FileWithSha256([IO.Stream]$Source, [string]$Destination) {
    $hash = [Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA256)
    $target = [IO.File]::Open($Destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $buffer = [byte[]]::new(8MB)
        while (($count = $Source.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $hash.AppendData($buffer, 0, $count)
            $target.Write($buffer, 0, $count)
        }
        $target.Flush($true)
        [Convert]::ToHexString($hash.GetHashAndReset()).ToLowerInvariant()
    } finally {
        $target.Dispose()
        $hash.Dispose()
    }
}

function Get-DestinationStorageIdentity([string]$Directory) {
    $root = [IO.Path]::GetPathRoot($Directory)
    if ($root -notmatch '^([A-Za-z]):\\$') {
        throw 'Destination must use a local Windows drive-letter path'
    }
    $driveLetter = $Matches[1]
    $volume = Get-Volume -DriveLetter $driveLetter
    $partition = Get-Partition -DriveLetter $driveLetter
    $disk = Get-Disk -Number $partition.DiskNumber
    if ($volume.DriveType.ToString() -ne 'Fixed') { throw 'Destination volume is not fixed storage' }
    if ($volume.FileSystemType -notin @('NTFS', 'ReFS')) { throw 'Destination must use NTFS or ReFS' }
    if ($disk.IsOffline -or $disk.OperationalStatus -notcontains 'Online') { throw 'Destination disk is not online' }
    if ($disk.BusType.ToString() -notin @('NVMe', 'SATA', 'SAS', 'RAID', 'StorageSpaces', 'SCM')) {
        throw "Destination disk bus type is not approved internal storage: $($disk.BusType)"
    }
    if (-not ($disk.IsBoot -or $disk.IsSystem)) {
        throw 'Destination must be on the reviewed Windows boot/system disk'
    }
    if (-not [string]::Equals($volume.UniqueId, $ExpectedVolumeUniqueId, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Destination volume identity does not match the reviewed volume'
    }
    if (-not [string]::Equals($disk.UniqueId, $ExpectedDiskUniqueId, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Destination disk identity does not match the reviewed disk'
    }
    [ordered]@{
        driveLetter = $driveLetter.ToUpperInvariant()
        volumeUniqueId = $volume.UniqueId
        diskUniqueId = $disk.UniqueId
        diskNumber = $disk.Number
        busType = $disk.BusType.ToString()
        isBoot = [bool]$disk.IsBoot
        isSystem = [bool]$disk.IsSystem
    }
}

if ($Distro -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { throw 'Invalid distro name' }
if ($Distro -notin @(Get-WslNames)) { throw 'Requested distro is not registered' }
if ($Distro -in @(Get-WslNames -Running)) {
    throw 'Stop the distro in an approved maintenance window before exporting; no automatic termination is performed'
}
$directory = [IO.Path]::GetFullPath($OutputDirectory)
$storage = Get-DestinationStorageIdentity $directory

# Reject aliases and redirection into another filesystem, including a WSL VHDX.
$ancestor = $directory
while ($ancestor) {
    if (Test-Path -LiteralPath $ancestor) {
        $item = Get-Item -LiteralPath $ancestor -Force
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Destination contains a redirected or non-directory component'
        }
    }
    $ancestor = Split-Path -Parent $ancestor
}

$sourceVhd = Get-DistroVhdPath $Distro
$generation = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$cloneName = "FullCapture-$Distro-$($generation.Substring($generation.Length - 8))"
if ($cloneName -in @(Get-WslNames)) { throw 'Generated capture-clone distro name already exists' }
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$partial = Join-Path $directory "$generation.partial"
$final = Join-Path $directory $generation
$cloneRoot = Join-Path $directory "capture-sources\$generation"
New-Item -ItemType Directory -Path $partial | Out-Null
New-Item -ItemType Directory -Path $cloneRoot | Out-Null
$archive = Join-Path $partial 'rootfs.tar.gz'
$cloneVhd = Join-Path $cloneRoot 'ext4.vhdx'

try {
    # Exclusive source access prevents WSL from obtaining the write handle
    # needed to start Debian4. Export operates only on the retained cold copy.
    $sourceLock = [IO.File]::Open($sourceVhd, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::None)
} catch {
    throw "Could not acquire the source VHDX capture lock; failed generation retained at $partial; stop all WSL activity first: $($_.Exception.Message)"
}

try {
    if ($Distro -in @(Get-WslNames -Running)) { throw 'Source became running before its VHDX capture lock was acquired' }
    $sourceVhdSha256 = Copy-FileWithSha256 $sourceLock $cloneVhd
    $cloneVhdSha256 = (Get-FileHash -LiteralPath $cloneVhd -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($cloneVhdSha256 -ne $sourceVhdSha256) { throw 'Cold VHDX copy checksum mismatch' }

    & wsl.exe --import-in-place $cloneName $cloneVhd
    if ($LASTEXITCODE -ne 0) { throw 'Cold capture-clone registration failed' }
    if ($Distro -in @(Get-WslNames -Running)) { throw 'Source was started during cold capture' }

    & wsl.exe --export $cloneName $archive --format tar.gz
    if ($LASTEXITCODE -ne 0) { throw 'WSL export of the cold capture clone failed' }
    if ($Distro -in @(Get-WslNames -Running)) { throw 'Source was started during clone export' }
    if ($cloneName -in @(Get-WslNames -Running)) { throw 'Capture clone was left running by export' }

    $stream = [IO.File]::OpenRead($archive)
    try {
        if ($stream.ReadByte() -ne 31 -or $stream.ReadByte() -ne 139) { throw 'Export is not gzip' }
    } finally {
        $stream.Dispose()
    }
    # Drain the full listing without logging private filenames.
    & tar.exe -tzf $archive | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Archive listing failed' }

    $storageAfter = Get-DestinationStorageIdentity $directory
    if ($storageAfter.volumeUniqueId -ne $storage.volumeUniqueId -or $storageAfter.diskUniqueId -ne $storage.diskUniqueId) {
        throw 'Destination storage identity changed during capture'
    }
    $manifest = [ordered]@{
        schemaVersion = 3
        format = 'wsl-full-tar.gz'
        distro = $Distro
        captureMethod = 'exclusive-cold-vhdx-copy-then-wsl-export'
        captureCloneDistro = $cloneName
        captureCloneVhdx = $cloneVhd
        captureCloneVhdxBytesBeforeRegistration = $sourceLock.Length
        sourceVhdxSha256 = $sourceVhdSha256
        coldCloneVhdxSha256BeforeRegistration = $cloneVhdSha256
        completedUtc = (Get-Date).ToUniversalTime().ToString('o')
        archive = 'rootfs.tar.gz'
        bytes = (Get-Item -LiteralPath $archive).Length
        sha256 = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
        exclusions = @()
        sourceState = 'stopped'
        restoreTested = $false
        storage = $storage
    }
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $partial 'manifest.json') -Encoding utf8NoBOM
    [IO.Directory]::Move($partial, $final)
} catch {
    throw "$($_.Exception.Message); failed generation retained at $partial; cold capture retained at $cloneRoot; source was not restarted"
} finally {
    $sourceLock.Dispose()
}
Write-Output "full_export_completed=$final"
