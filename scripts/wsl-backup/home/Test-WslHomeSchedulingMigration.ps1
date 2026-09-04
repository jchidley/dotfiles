#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$Candidate = if ($env:WSL_HOME_MIGRATION_CANDIDATE) { $env:WSL_HOME_MIGRATION_CANDIDATE } else { Join-Path $PSScriptRoot 'Migrate-WslHomeScheduling.ps1' }
$Root = Join-Path ([IO.Path]::GetTempPath()) ('wsl-home-migration-test.' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($Root) | Out-Null
$Assertions = 0
function Assert-True([bool]$Condition, [string]$Message) { $script:Assertions++; if (-not $Condition) { throw "ASSERTION FAILED: $Message" } }
function Expect-Failure([scriptblock]$Operation, [string]$Pattern, [string]$Message) {
    $script:Assertions++
    $failure = $null
    try { & $Operation | Out-Null } catch { $failure = $_ }
    if (-not $failure) { throw "ASSERTION FAILED: $Message (operation succeeded)" }
    if ($failure.Exception.Message -notmatch $Pattern) { throw "ASSERTION FAILED: $Message ($($failure.Exception.Message))" }
}
$Names = @('Backup','Monitor','Retention','Prune','Check','Read Data Check') | ForEach-Object { "WSL Home Restic - $_" }
function New-Task([string]$Name, [bool]$Enabled = $true, [string]$Suffix = '') {
    $enabledText = $Enabled.ToString().ToLowerInvariant()
    $xml = "<Task><Triggers><CalendarTrigger><StartBoundary>2026-01-01T00:00:00$Suffix</StartBoundary></CalendarTrigger></Triggers><Principals><Principal id=`"Author`"><UserId>fixture</UserId></Principal></Principals><Settings><Enabled>$enabledText</Enabled><StartWhenAvailable>true</StartWhenAvailable></Settings><Actions><Exec><Command>wsl.exe</Command><Arguments>-d Debian-Recovered -- fixture $Suffix</Arguments></Exec></Actions></Task>"
    [pscustomobject]@{ Name = $Name; Path = '\'; Enabled = $Enabled; Xml = $xml }
}
function New-Fixture([string]$Name, [object[]]$Tasks) {
    $fixture = Join-Path $Root $Name
    [IO.Directory]::CreateDirectory($fixture) | Out-Null
    ConvertTo-Json @($Tasks) -Depth 10 | Set-Content -LiteralPath (Join-Path $fixture 'tasks.json') -Encoding utf8NoBOM
    return $fixture
}
function Invoke-Migration([string]$Fixture, [string]$Action, [string]$FailAfter = '', [string]$Observation = '') {
    $arguments = @{ Action=$Action; FixtureRoot=$Fixture; MigrationDirectory=(Join-Path $Fixture 'migration') }
    if ($FailAfter) { $arguments.FixtureFailAfter = $FailAfter }
    if ($Observation) { $arguments.ObservationCompleteRecord = $Observation }
    & $Candidate @arguments
}
function Read-Tasks([string]$Fixture) { @(Get-Content (Join-Path $Fixture 'tasks.json') -Raw | ConvertFrom-Json) }
function Assert-ExactOriginal([string]$Fixture, [object[]]$Original, [string]$Message) {
    $actual = Read-Tasks $Fixture
    Assert-True ($actual.Count -eq 6) "$Message count"
    for ($i=0; $i -lt 6; $i++) {
        $expected = $Original[$i]
        $restored = @($actual | Where-Object { $_.Name -ceq $expected.Name -and $_.Path -ceq $expected.Path })[0]
        Assert-True ($restored.Xml -ceq $expected.Xml -and $restored.Enabled -eq $expected.Enabled) "$Message exact XML/enabled state $i"
    }
}
try {
    $original = @()
    for ($i=0; $i -lt 6; $i++) { $original += New-Task $Names[$i] ($i -ne 3) "-$i" }
    $fixture = New-Fixture complete $original
    Invoke-Migration $fixture Inventory | Out-Null
    $inventoryPath = Join-Path $fixture 'migration/legacy-task-inventory.json'
    Assert-True (Test-Path $inventoryPath) 'complete six-task inventory is durable'
    $inventory = Get-Content $inventoryPath -Raw | ConvertFrom-Json
    Assert-True ($inventory.Tasks.Count -eq 6) 'complete six-task inventory captures all tasks'
    Assert-True (@($inventory.Tasks | Where-Object { $_.XmlSha256 -notmatch '^[0-9a-f]{64}$' }).Count -eq 0) 'inventory retains cryptographic XML hashes'
    Assert-True (@($inventory.Tasks | Where-Object { -not $_.Triggers -or -not $_.Actions -or -not $_.Principal -or -not $_.Settings }).Count -eq 0) 'inventory captures triggers actions principal and settings'
    Invoke-Migration $fixture InstallOrVerifyLinux | Out-Null
    $linux = Get-Content (Join-Path $fixture 'linux.json') -Raw | ConvertFrom-Json
    Assert-True ($linux.Installed -and $linux.ManualVerified -and -not $linux.Enabled) 'Linux units install and verify without implicit enablement'

    $driftFixture = New-Fixture drift $original
    Invoke-Migration $driftFixture Inventory | Out-Null
    Invoke-Migration $driftFixture InstallOrVerifyLinux | Out-Null
    $drifted = Read-Tasks $driftFixture
    $drifted[0].Xml = $drifted[0].Xml.Replace('fixture -0','fixture drifted')
    ConvertTo-Json $drifted -Depth 10 | Set-Content (Join-Path $driftFixture 'tasks.json') -Encoding utf8NoBOM
    Expect-Failure { Invoke-Migration $driftFixture DisableLegacy } 'drift' 'drifted task fails closed before disable'
    Assert-True ((Read-Tasks $driftFixture)[0].Enabled) 'inventory drift refusal changes no task'

    foreach ($case in @(
        @{N='missing'; T=$original[0..4]},
        @{N='duplicate'; T=@($original + $original[0])},
        @{N='renamed'; T=@(@(New-Task 'WSL Home Restic - Renamed') + @($original[1..5]))},
        @{N='unexpected'; T=@($original + (New-Task 'WSL Home Restic - Surprise'))}
    )) {
        $bad = New-Fixture $case.N $case.T
        Expect-Failure { Invoke-Migration $bad Inventory } 'Expected exactly six|Missing, duplicate|Unexpected' "$($case.N) task set fails closed"
    }

    foreach ($point in 'AfterJournal','AfterFirstDisable','AfterAllDisabled','AfterLinuxEnable','AfterVerification') {
        $interrupted = New-Fixture ("interrupt-$point") $original
        Invoke-Migration $interrupted Inventory | Out-Null
        Invoke-Migration $interrupted InstallOrVerifyLinux | Out-Null
        Expect-Failure { Invoke-Migration $interrupted DisableLegacy $point } 'rollback was verified' "interruption $point triggers verified rollback"
        Assert-ExactOriginal $interrupted $original "interruption $point rollback"
        $state = Get-Content (Join-Path $interrupted 'linux.json') -Raw | ConvertFrom-Json
        Assert-True (-not $state.Enabled) "interruption $point disables Linux timer"
        $journal = Get-Content (Join-Path $interrupted 'migration/migration-state.json') -Raw | ConvertFrom-Json
        Assert-True ($journal.State -eq 'RolledBack') "interruption $point records stable rollback"
    }

    Invoke-Migration $fixture DisableLegacy | Out-Null
    Assert-True (@(Read-Tasks $fixture | Where-Object Enabled).Count -eq 0) 'independent read-back proves all six tasks disabled'
    $linux = Get-Content (Join-Path $fixture 'linux.json') -Raw | ConvertFrom-Json
    Assert-True ($linux.Enabled) 'explicit cutover enables Linux timer'
    Invoke-Migration $fixture Verify | Out-Null
    Assert-True ((Get-Content (Join-Path $fixture 'migration/migration-state.json') -Raw | ConvertFrom-Json).State -eq 'CutoverComplete') 'cutover verification records a stable state'
    Expect-Failure { Invoke-Migration $fixture DeleteAfterObservation } 'observation-complete record' 'deletion is refused without explicit observation completion'
    $falseObservation = Join-Path $fixture 'observation-false.json'
    @{ ObservationComplete=$false; InventoryTaskSetSha256=$inventory.TaskSetSha256 } | ConvertTo-Json | Set-Content $falseObservation
    Expect-Failure { Invoke-Migration $fixture DeleteAfterObservation '' $falseObservation } 'absent, false' 'false observation record cannot authorize deletion'
    Assert-True ((Read-Tasks $fixture).Count -eq 6) 'refused deletion retains every legacy task'

    Invoke-Migration $fixture RestoreLegacy | Out-Null
    Assert-ExactOriginal $fixture $original 'explicit rollback'
    Invoke-Migration $fixture Verify | Out-Null
    Assert-True (-not (Get-Content (Join-Path $fixture 'linux.json') -Raw | ConvertFrom-Json).Enabled) 'independent rollback read-back proves Linux timer disabled'

    $sourceRoot = Split-Path $PSScriptRoot -Parent
    Assert-True (-not (Test-Path (Join-Path $PSScriptRoot 'Register-WindowsTasks.ps1'))) 'obsolete Register-WindowsTasks.ps1 is absent from active source'
    $setupSource = Get-Content (Join-Path $sourceRoot 'setup.sh') -Raw
    Assert-True ($setupSource -notmatch 'Register-WindowsTasks\.ps1|systemctl enable|systemctl start') 'ordinary setup neither registers Windows tasks nor enables Linux scheduling'
    $activeEntryPoints = @((Join-Path $sourceRoot 'setup.sh'), (Join-Path $sourceRoot 'Install-Windows.ps1'))
    Assert-True (-not ($activeEntryPoints | Select-String -Pattern 'wsl\.exe.+(backup|status|retention|prune|check)|Register-WindowsTasks' -Quiet)) 'no active Windows component starts WSL for routine work'
    "WslHomeSchedulingMigration retained tests passed: $Assertions assertions"
} finally {
    Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue
}
