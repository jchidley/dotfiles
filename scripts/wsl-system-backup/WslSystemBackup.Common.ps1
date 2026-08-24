function Convert-ToWslPath {
    param([Parameter(Mandatory = $true)][string] $WindowsPath)
    if ($WindowsPath -notmatch '^[A-Za-z]:[\\/]') {
        throw "Path is not on a Windows drive: $WindowsPath"
    }
    $full = [IO.Path]::GetFullPath($WindowsPath)
    if ($full -notmatch '^([A-Za-z]):\\(.*)$') {
        throw "Path is not on a Windows drive: $full"
    }
    $drive = $Matches[1].ToLowerInvariant()
    $relative = $Matches[2].Replace('\', '/')
    return "/mnt/$drive/$relative"
}

function Get-BackupTaskState {
    param(
        [string] $Pattern = 'WSL Home Restic - *',
        [int] $ExpectedCount = 6,
        [scriptblock] $GetTasks = { param($p) @(Get-ScheduledTask -TaskName $p -ErrorAction SilentlyContinue) }
    )
    $tasks = @(& $GetTasks $Pattern)
    if ($tasks.Count -ne $ExpectedCount) {
        throw "Expected $ExpectedCount Restic tasks, found $($tasks.Count)"
    }
    $running = @($tasks | Where-Object { $_.State.ToString() -eq 'Running' })
    if ($running.Count -gt 0) {
        throw "Restic tasks are currently running: $($running.TaskName -join ', ')"
    }
    return @($tasks | ForEach-Object {
        [pscustomobject]@{
            Name = $_.TaskName
            WasEnabled = ($_.State.ToString() -ne 'Disabled')
        }
    })
}

function Suspend-BackupTasks {
    param(
        [Parameter(Mandatory = $true)][object[]] $TaskState,
        [scriptblock] $DisableTask = { param($n) Disable-ScheduledTask -TaskName $n | Out-Null },
        [scriptblock] $EnableTask = { param($n) Enable-ScheduledTask -TaskName $n | Out-Null },
        [scriptblock] $GetTasks = { param($p) @(Get-ScheduledTask -TaskName $p -ErrorAction SilentlyContinue) },
        [string] $Pattern = 'WSL Home Restic - *'
    )
    $disabled = [Collections.Generic.List[string]]::new()
    try {
        foreach ($entry in @($TaskState | Where-Object WasEnabled)) {
            & $DisableTask $entry.Name
            $disabled.Add($entry.Name)
        }
        $raced = @(& $GetTasks $Pattern | Where-Object { $_.State.ToString() -eq 'Running' })
        if ($raced.Count -gt 0) {
            throw "Restic tasks started during suspension: $($raced.TaskName -join ', ')"
        }
    }
    catch {
        foreach ($name in $disabled) {
            try { & $EnableTask $name } catch { }
        }
        throw
    }
}

function Restore-BackupTaskState {
    param(
        [Parameter(Mandatory = $true)][object[]] $TaskState,
        [scriptblock] $EnableTask = { param($n) Enable-ScheduledTask -TaskName $n | Out-Null },
        [scriptblock] $DisableTask = { param($n) Disable-ScheduledTask -TaskName $n | Out-Null }
    )
    $errors = [Collections.Generic.List[string]]::new()
    foreach ($entry in $TaskState) {
        try {
            if ($entry.WasEnabled) {
                & $EnableTask $entry.Name
            }
            else {
                & $DisableTask $entry.Name
            }
        }
        catch {
            $errors.Add("$($entry.Name): $($_.Exception.Message)")
        }
    }
    if ($errors.Count -gt 0) {
        throw "Could not restore task state: $($errors -join '; ')"
    }
}

function Test-ExportClientActive {
    param(
        [Parameter(Mandatory = $true)][string] $Distro,
        [scriptblock] $GetProcesses = { @(Get-CimInstance Win32_Process -Filter "Name = 'wsl.exe'" -ErrorAction SilentlyContinue) }
    )
    $escaped = [regex]::Escape($Distro)
    return (@(& $GetProcesses | Where-Object { $_.CommandLine -match "--export\s+$escaped(?:\s|$)" }).Count -gt 0)
}

function Write-AtomicJson {
    param(
        [Parameter(Mandatory = $true)] $Value,
        [Parameter(Mandatory = $true)][string] $Path,
        [int] $Depth = 8
    )
    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $temporary = "$Path.$([guid]::NewGuid().ToString('N')).partial"
    try {
        $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $temporary -Encoding UTF8
        Move-Item -LiteralPath $temporary -Destination $Path -Force
    }
    finally {
        Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
    }
}

function Read-RunJournal {
    param([Parameter(Mandatory = $true)][string] $Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try { return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json) }
    catch { throw "Run journal is malformed: $Path ($($_.Exception.Message))" }
}

function Test-JournalProcessActive {
    param([Parameter(Mandatory = $true)] $Journal)
    $process = Get-Process -Id ([int]$Journal.ProcessId) -ErrorAction SilentlyContinue
    if (-not $process) { return $false }
    try {
        $expected = [datetime]::Parse($Journal.ProcessStartedAt)
        return ([math]::Abs(($process.StartTime - $expected).TotalSeconds) -lt 2)
    }
    catch { return $false }
}

function Get-BackupArtifacts {
    param([Parameter(Mandatory = $true)][string] $Directory)
    if (-not (Test-Path -LiteralPath $Directory)) { return @() }
    return @(Get-ChildItem -LiteralPath $Directory -File -Force | Where-Object {
        $_.Name -match '\.tar\.gz\.(partial|partial\.failed|partial\.interrupted|failed)$' -or
        $_.Name -match '\.manifest\.json\.partial$'
    })
}

function Test-BackupManifest {
    param(
        [Parameter(Mandatory = $true)][string] $ManifestPath,
        [switch] $SkipHash
    )
    $resolvedManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
    try { $manifest = Get-Content -LiteralPath $resolvedManifest -Raw | ConvertFrom-Json }
    catch { throw "Manifest is not valid JSON: $resolvedManifest ($($_.Exception.Message))" }

    foreach ($property in 'SchemaVersion','Distro','Archive','ArchiveBytes','Sha256','Format','Validation','WslVersion') {
        if ($null -eq $manifest.$property) { throw "Manifest property is missing: $property" }
    }
    if ($manifest.SchemaVersion -ne 1) { throw "Unsupported manifest schema: $($manifest.SchemaVersion)" }
    if ($manifest.Format -ne 'tar.gz') { throw "Unexpected archive format: $($manifest.Format)" }
    if ([IO.Path]::GetFileName($manifest.Archive) -ne $manifest.Archive) { throw 'Manifest archive must be a leaf filename' }
    if ($manifest.Sha256 -notmatch '^[0-9a-f]{64}$') { throw 'Manifest SHA-256 is malformed' }
    if ($manifest.Validation -is [array]) { throw 'Manifest Validation must be an object, not an array' }
    if ($manifest.Validation.Result -ne 'passed') { throw 'Manifest validation result is not passed' }
    if ([int64]$manifest.Validation.Files -lt 1 -or [int64]$manifest.Validation.PiSessions -lt 1) {
        throw 'Manifest validation counts are invalid'
    }
    if ([string]::IsNullOrWhiteSpace($manifest.WslVersion)) { throw 'Manifest WSL version is empty' }
    if ($manifest.WslVersion -match "`0") { throw 'Manifest WSL version contains NUL characters' }

    $archivePath = Join-Path (Split-Path -Parent $resolvedManifest) $manifest.Archive
    if (-not (Test-Path -LiteralPath $archivePath)) { throw "Archive is absent: $archivePath" }
    $archive = Get-Item -LiteralPath $archivePath
    if ($archive.Length -ne [int64]$manifest.ArchiveBytes) {
        throw "Archive size mismatch: $($archive.Length) != $($manifest.ArchiveBytes)"
    }
    $actualHash = $null
    if (-not $SkipHash) {
        $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne $manifest.Sha256) { throw "Archive SHA-256 mismatch: $actualHash" }
    }
    return [pscustomobject]@{
        Result = 'passed'
        Manifest = $resolvedManifest
        Archive = $archivePath
        ArchiveBytes = $archive.Length
        Sha256 = $(if ($actualHash) { $actualHash } else { $manifest.Sha256 })
        Files = [int64]$manifest.Validation.Files
        PiSessions = [int64]$manifest.Validation.PiSessions
        HashRead = (-not $SkipHash)
    }
}

function Get-OldBackupGenerations {
    param(
        [Parameter(Mandatory = $true)][string] $Directory,
        [Parameter(Mandatory = $true)][string] $Distro,
        [int] $Keep = 2
    )
    if (-not (Test-Path -LiteralPath $Directory)) { return @() }
    return @(Get-ChildItem -LiteralPath $Directory -Filter "*_${Distro}.tar.gz" -File |
        Sort-Object Name -Descending | Select-Object -Skip $Keep)
}
