#requires -Version 7.0
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

function Invoke-TestProcess {
    param([string]$TestPath,[string]$CandidatePath)
    $psi=[Diagnostics.ProcessStartInfo]::new((Get-Command pwsh.exe -CommandType Application | Select-Object -First 1).Source)
    $psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    foreach ($argument in @('-NoLogo','-NoProfile','-NonInteractive','-File',$TestPath,'-CandidatePath',$CandidatePath)) { $psi.ArgumentList.Add($argument) }
    $process=[Diagnostics.Process]::new();$process.StartInfo=$psi;$null=$process.Start()
    $stdout=$process.StandardOutput.ReadToEnd();$stderr=$process.StandardError.ReadToEnd()
    if (-not $process.WaitForExit(180000)) { $process.Kill($true); throw 'Phase 3 mutation test timed out' }
    [pscustomobject]@{ExitCode=$process.ExitCode;Text="$stdout`n$stderr"}
}

$source=Join-Path $PSScriptRoot 'Invoke-WslHomeLongJobConsent.ps1'
$common=Join-Path $PSScriptRoot 'WslHomeRestic.Common.ps1'
$retainedTest=Join-Path $PSScriptRoot 'Test-WslHomeLongJobConsent.ps1'
$root=Join-Path ([IO.Path]::GetTempPath()) ('wsl-long-job-mutations-'+[guid]::NewGuid())
$mutations=@(
    [pscustomobject]@{
        Name='remove-consent';Old="if (`$prompt.Decision -ne 'Yes') {";New='if ($false) {'
        Pattern='No never runs the operation and keeps it due'
    },
    [pscustomobject]@{
        Name='ignore-snooze';Old='if ($null -ne $operationState.SnoozeUntil -and [datetimeoffset]$Now -lt [datetimeoffset]$operationState.SnoozeUntil) {';New='if ($false -and $null -ne $operationState.SnoozeUntil) {'
        Pattern='snooze suppresses prompts just before its exact boundary'
    },
    [pscustomobject]@{
        Name='dispatch-different-operation';Old='$commandPath = Join-Path (Split-Path -Parent $PolicyPath) $operation.CommandFile';New="`$commandPath = Join-Path (Split-Path -Parent `$PolicyPath) 'alternate-operation.ps1'"
        Pattern='fixed reviewed operation identity reaches the command unchanged'
    },
    [pscustomobject]@{
        Name='allow-absent-session';Old='if (-not $interactive.Interactive) {';New='if ($false -and -not $interactive.Interactive) {'
        Pattern='absent interactive session defers before prompting or running'
    },
    [pscustomobject]@{
        Name='allow-battery-power';Old='if ($policy.RequireAcPower -and -not $power.OnAc) {';New='if ($false -and $policy.RequireAcPower -and -not $power.OnAc) {'
        Pattern='battery policy prevents prompting and running'
    },
    [pscustomobject]@{
        Name='skip-sleep-release';Old='if ($null -ne $sleepToken) {';New='if ($false -and $null -ne $sleepToken) {'
        Pattern='idle-sleep inhibition is released after approved success'
    },
    [pscustomobject]@{
        Name='complete-failed-or-interrupted';Old="# MUTATION-SEAM: failed or interrupted work remains due.`n        `$operationState.Due = `$true";New="# MUTATION-SEAM: failed or interrupted work remains due.`n        `$operationState.Due = `$false"
        Pattern='Failed work remains due'
    }
)

New-Item -ItemType Directory -Path $root | Out-Null
try {
    $original=Get-Content -LiteralPath $source -Raw
    foreach ($mutation in $mutations) {
        $occurrences=([regex]::Matches($original,[regex]::Escape($mutation.Old))).Count
        if ($occurrences -ne 1) { throw "Mutation $($mutation.Name) expected one source seam, found $occurrences" }
        $mutationRoot=Join-Path $root $mutation.Name;New-Item -ItemType Directory -Path $mutationRoot | Out-Null
        $mutated=Join-Path $mutationRoot 'Invoke-WslHomeLongJobConsent.ps1'
        Copy-Item -LiteralPath $common -Destination (Join-Path $mutationRoot 'WslHomeRestic.Common.ps1')
        Set-Content -LiteralPath $mutated -Encoding UTF8 -Value $original.Replace($mutation.Old,$mutation.New)
        $tokens=$null;$parserErrors=$null
        [void][Management.Automation.Language.Parser]::ParseFile($mutated,[ref]$tokens,[ref]$parserErrors)
        if ($parserErrors.Count -gt 0) { throw "Mutation $($mutation.Name) produced a parser error: $($parserErrors[0].Message)" }
        $result=Invoke-TestProcess $retainedTest $mutated
        if ($result.ExitCode -eq 0) { throw "Mutation survived: $($mutation.Name)" }
        if ($result.Text -notmatch [regex]::Escape($mutation.Pattern)) { throw "Mutation $($mutation.Name) failed at the wrong seam. Expected '$($mutation.Pattern)'. Output: $($result.Text)" }
        if ($result.Text -match 'ParserError|expected one source seam|Child timed out|mutation test timed out') { throw "Mutation $($mutation.Name) produced an invalid trial: $($result.Text)" }
        Write-Output "Killed mutation $($mutation.Name): $($mutation.Pattern)"
    }
} finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
Write-Output "WslHomeLongJobConsent semantic mutations killed: $($mutations.Count)"
