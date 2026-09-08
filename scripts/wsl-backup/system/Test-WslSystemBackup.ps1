#requires -Version 7.0
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'WslSystemBackup.Common.ps1')
$tests = 0
function Assert-True([bool]$Condition, [string]$Message) { $script:tests++; if (-not $Condition) { throw "ASSERTION FAILED: $Message" } }
function Expect-Throw([scriptblock]$Action, [string]$Pattern) {
    $script:tests++; $missing="Expected action to throw: $Pattern"
    try { & $Action; throw $missing } catch { if ($_.Exception.Message -eq $missing) { throw }; if ($_.Exception.Message -notmatch $Pattern) { throw } }
}
$root = Join-Path $env:TEMP ('combined-system-controller-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $root | Out-Null
try {
    $config = Read-CombinedBackupConfig (Join-Path $PSScriptRoot 'combined-backup.json')
    Assert-True ($config.distro -eq 'Debian4') 'configuration is bound to Debian4'
    Assert-True ($config.externalRepositoryId -eq 'dc377d8f1b5ce2a32183be56cd6ffce1222f776f0db73b07fc8f4ecfa0b44eb5') 'external repository identity is pinned'
    $volume = [pscustomobject]@{UniqueId=$config.volumeId;FileSystemLabel=$config.targetLabel;FileSystem='NTFS';DriveLetter='Z';SizeRemaining=99GB}
    $partition = [pscustomobject]@{Number=1}
    $disk = [pscustomobject]@{Guid=$config.diskGuid;BusType='USB';IsOffline=$false}
    $target = Resolve-CombinedBackupTarget $config { @($volume) } { @($partition) } { @($disk) }
    Assert-True ($target.Root -eq 'Z:\') 'verified identity resolves only its current transport root'
    $wrongDisk = [pscustomobject]@{Guid=[guid]::NewGuid();BusType='USB';IsOffline=$false}
    Expect-Throw { Resolve-CombinedBackupTarget $config { @($volume) } { @($partition) } { @($wrongDisk) } } 'physical-disk identity'
    $badVolume = [pscustomobject]@{UniqueId=$config.volumeId;FileSystemLabel='lookalike';FileSystem='NTFS';DriveLetter='Z';SizeRemaining=99GB}
    Expect-Throw { Resolve-CombinedBackupTarget $config { @($badVolume) } { @($partition) } { @($disk) } } 'label or filesystem'
    $unsafeConfig = Join-Path $root 'unsafe-config.json'
    $config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $unsafeConfig
    $unsafe = Get-Content -LiteralPath $unsafeConfig -Raw | ConvertFrom-Json
    $unsafe.systemRelativePath = '..\escape'
    $unsafe | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $unsafeConfig
    Expect-Throw { Read-CombinedBackupConfig $unsafeConfig } 'unsafe'

    $journal = Join-Path $root 'state/journal.json'
    Write-AtomicJson @{stage='first'} $journal
    Write-AtomicJson @{stage='second'} $journal
    Assert-True ((Get-Content -LiteralPath $journal -Raw | ConvertFrom-Json).stage -eq 'second') 'journal generations replace atomically'
    $partial = Join-Path $root 'generation.partial'; $final = Join-Path $root 'generation'
    New-Item -ItemType Directory $partial | Out-Null
    Expect-Throw { Complete-CombinedGeneration $partial $final } 'manifest.json'
    Assert-True (-not (Test-Path $final)) 'interrupted generation is not promoted'
    Set-Content (Join-Path $partial 'manifest.json') '{"fixture":true}'
    Complete-CombinedGeneration $partial $final
    Assert-True ((Test-Path $final) -and -not (Test-Path $partial)) 'manifest generation promotes by one directory rename'
    Write-Output "WslSystemBackup tests passed: $tests assertions"
}
finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
