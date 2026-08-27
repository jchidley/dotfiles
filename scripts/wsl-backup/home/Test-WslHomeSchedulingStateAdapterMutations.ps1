#requires -Version 7.0
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

function Invoke-TestProcess {
    param([string] $TestPath, [string] $AdapterPath)
    $psi = [Diagnostics.ProcessStartInfo]::new((Get-Command pwsh.exe -CommandType Application | Select-Object -First 1).Source)
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($argument in @('-NoLogo','-NoProfile','-NonInteractive','-File',$TestPath,'-AdapterPath',$AdapterPath)) {
        $psi.ArgumentList.Add($argument)
    }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $psi
    $null = $process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    if (-not $process.WaitForExit(300000)) { $process.Kill($true); throw 'Mutation test timed out' }
    [pscustomobject]@{ExitCode=$process.ExitCode; Text="$stdout`n$stderr"}
}

$source = Join-Path $PSScriptRoot 'Invoke-WslHomeSchedulingStateAdapter.ps1'
$common = Join-Path $PSScriptRoot 'WslHomeRestic.Common.ps1'
$retainedTest = Join-Path $PSScriptRoot 'Test-WslHomeSchedulingStateAdapter.ps1'
$root = Join-Path ([IO.Path]::GetTempPath()) ('wsl-state-mutations-' + [guid]::NewGuid())
$mutations = @(
    [pscustomobject]@{
        Name='threshold-off-by-one';
        Old='if ($count -lt $threshold) { return $false }';
        New='if ($count -le $threshold) { return $false }';
        Pattern='second eligible failure warns even when attempts are weeks apart'
    },
    [pscustomobject]@{
        Name='ineligible-periodic-runs';
        Old='$due = $Opportunity -ne ''Periodic'' -or $null -eq $state.LastAttemptAwakeMinute -or';
        New='$due = $true -or $Opportunity -ne ''Periodic'' -or $null -eq $state.LastAttemptAwakeMinute -or';
        Pattern='weeks of suspension do not create an awake-time attempt'
    },
    [pscustomobject]@{
        Name='success-preserves-failures';
        Old="# MUTATION-SEAM: success resets both consecutive counters.`n            `$state.ConsecutiveBackupFailures = 0";
        New="# MUTATION-SEAM: success resets both consecutive counters.`n            `$state.ConsecutiveBackupFailures = `$state.ConsecutiveBackupFailures";
        Pattern='no-change success resets both counters and opens backup gate'
    },
    [pscustomobject]@{
        Name='unknown-schema-accepted';
        Old="if ((Assert-JsonInteger `$State.SchemaVersion 'State.SchemaVersion' 2 2) -ne 2) {`n        throw 'Unsupported coordinator state schema version'`n    }";
        New="Assert-JsonInteger `$State.SchemaVersion 'State.SchemaVersion' 2 99 | Out-Null";
        Pattern='unknown state schema fails closed'
    },
    [pscustomobject]@{
        Name='pending-attempt-infers-success';
        Old="`$state.LastCoordinatorAttempt = `$Now.ToUniversalTime().ToString('o')`n    if (`$Opportunity -eq 'Resume')";
        New="`$state.LastCoordinatorAttempt = `$Now.ToUniversalTime().ToString('o')`n    `$state.LastCoordinatorSuccess = `$state.LastCoordinatorAttempt`n    if (`$Opportunity -eq 'Resume')";
        Pattern='interruption never infers backup success'
    },
    [pscustomobject]@{
        Name='before-replace-fault-removed';
        Old="Invoke-AdapterFault `$Phase 'BeforeReplace'";
        New="Invoke-AdapterFault `$Phase 'RemovedBeforeReplaceFault'";
        Pattern='Pending:BeforeReplace terminates the child process'
    },
    [pscustomobject]@{
        Name='success-preserves-notification-episode';
        Old="# MUTATION-SEAM: successful attempts end the prior notification episode.`n        `$State.NotificationEpisode.Signature = `$null`n        `$State.NotificationEpisode.LastNotifiedAt = `$null";
        New="# MUTATION-SEAM: successful attempts end the prior notification episode.`n        `$State.NotificationEpisode.Signature = `$State.NotificationEpisode.Signature`n        `$State.NotificationEpisode.LastNotifiedAt = `$State.NotificationEpisode.LastNotifiedAt";
        Pattern='success ends the notification episode'
    },
    [pscustomobject]@{
        Name='failed-backup-opens-maintenance-gate';
        Old='$backupGateSatisfied = $false';
        New='$backupGateSatisfied = $true';
        Pattern='failure blocks the backup-before-maintenance gate'
    }
)

New-Item -ItemType Directory -Path $root | Out-Null
try {
    $original = Get-Content -LiteralPath $source -Raw
    foreach ($mutation in $mutations) {
        $occurrences = ([regex]::Matches($original, [regex]::Escape($mutation.Old))).Count
        if ($occurrences -ne 1) { throw "Mutation $($mutation.Name) expected one source seam, found $occurrences" }
        $mutationRoot = Join-Path $root $mutation.Name
        New-Item -ItemType Directory -Path $mutationRoot | Out-Null
        $mutated = Join-Path $mutationRoot 'Invoke-WslHomeSchedulingStateAdapter.ps1'
        Copy-Item -LiteralPath $common -Destination (Join-Path $mutationRoot 'WslHomeRestic.Common.ps1')
        Set-Content -LiteralPath $mutated -Encoding UTF8 -Value $original.Replace($mutation.Old, $mutation.New)
        $result = Invoke-TestProcess $retainedTest $mutated
        if ($result.ExitCode -eq 0) { throw "Mutation survived: $($mutation.Name)" }
        if ($result.Text -notmatch [regex]::Escape($mutation.Pattern)) {
            throw "Mutation $($mutation.Name) failed at the wrong seam. Expected '$($mutation.Pattern)'. Output: $($result.Text)"
        }
        if ($result.Text -match 'ParserError|Mutation harness|Unexpected error') {
            throw "Mutation $($mutation.Name) produced an invalid trial: $($result.Text)"
        }
        Write-Output "Killed mutation $($mutation.Name): $($mutation.Pattern)"
    }
} finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output "WslHomeSchedulingStateAdapter semantic mutations killed: $($mutations.Count)"
