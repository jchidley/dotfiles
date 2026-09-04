#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$Source = Join-Path $PSScriptRoot 'Migrate-WslHomeScheduling.ps1'
$Retained = Join-Path $PSScriptRoot 'Test-WslHomeSchedulingMigration.ps1'
$Root = Join-Path ([IO.Path]::GetTempPath()) ('wsl-home-migration-mutations.' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($Root) | Out-Null
$Mutations = @(
    [pscustomobject]@{
        Name='accept-incomplete-inventory'
        Old="if (`$Tasks.Count -ne `$ExpectedNames.Count) { throw `"Expected exactly six matching legacy tasks; found `$(`$Tasks.Count)`" }`n    foreach (`$name in `$ExpectedNames) {`n        `$taskMatches = @(`$Tasks | Where-Object { `$_.Name -ceq `$name -and `$_.Path -ceq '\' })`n        if (`$taskMatches.Count -ne 1) { throw `"Missing, duplicate, renamed, or non-root legacy task: `$name`" }`n    }`n    `$unexpected = @(`$Tasks | Where-Object { `$_.Name -cnotin `$ExpectedNames -or `$_.Path -cne '\' })`n    if (`$unexpected.Count) { throw `"Unexpected matching legacy task: `$(`$unexpected[0].Path)`$(`$unexpected[0].Name)`" }"
        New="if (`$Tasks.Count -gt 7) { throw 'too many tasks' }"
        Assertion='missing task set fails closed'
    },
    [pscustomobject]@{
        Name='ignore-definition-drift'
        Old="if ((Get-TextSha256 `$actual.Xml) -cne `$captured.XmlSha256 -or `$actual.Enabled -ne `$captured.Enabled) {`n            throw `"Legacy task drift detected: `$(`$captured.Name)`"`n        }"
        New="if (`$false) { throw 'unreachable drift' }"
        Assertion='drifted task fails closed before disable'
    },
    [pscustomobject]@{
        Name='rollback-loses-enabled-state'
        Old="[pscustomobject]@{ Name = `$_.Name; Path = `$_.Path; Enabled = [bool]`$_.Enabled; Xml = `$_.Xml }"
        New="[pscustomobject]@{ Name = `$_.Name; Path = `$_.Path; Enabled = `$false; Xml = `$_.Xml }"
        Assertion='triggers verified rollback'
    },
    [pscustomobject]@{
        Name='skip-automatic-rollback'
        Old="`$failure = `$_`n            Invoke-Rollback `$inventory`n            throw `"Cutover failed and exact rollback was verified: `$failure`""
        New="`$failure = `$_`n            throw `"Cutover failed without rollback: `$failure`""
        Assertion='triggers verified rollback'
    },
    [pscustomobject]@{
        Name='accept-false-observation-record'
        Old='if ($observation.ObservationComplete -ne $true -or $observation.InventoryTaskSetSha256 -cne $inventory.TaskSetSha256)'
        New='if ($observation.ObservationComplete -eq $true -or $observation.InventoryTaskSetSha256 -cne $inventory.TaskSetSha256)'
        Assertion='false observation record cannot authorize deletion'
    }
)
try {
    foreach ($mutation in $Mutations) {
        $text = Get-Content -LiteralPath $Source -Raw
        $count = ([regex]::Matches($text, [regex]::Escape($mutation.Old))).Count
        if ($count -ne 1) { throw "Mutation $($mutation.Name) expected one seam, found $count" }
        $candidate = Join-Path $Root ($mutation.Name + '.ps1')
        [IO.File]::WriteAllText($candidate, $text.Replace($mutation.Old, $mutation.New), [Text.UTF8Encoding]::new($false))
        $tokens=$null; $errors=$null
        [Management.Automation.Language.Parser]::ParseFile($candidate, [ref]$tokens, [ref]$errors) | Out-Null
        if ($errors.Count) { throw "Mutation $($mutation.Name) is parser-invalid: $($errors[0])" }
        $env:WSL_HOME_MIGRATION_CANDIDATE = $candidate
        $output = & pwsh.exe -NoLogo -NoProfile -NonInteractive -File $Retained 2>&1 | Out-String
        $code = $LASTEXITCODE
        Remove-Item Env:WSL_HOME_MIGRATION_CANDIDATE -ErrorAction SilentlyContinue
        if ($code -eq 0) { throw "Mutation survived: $($mutation.Name)" }
        if ($output -notmatch [regex]::Escape($mutation.Assertion)) { throw "Mutation $($mutation.Name) died at wrong assertion; expected $($mutation.Assertion): $output" }
        if ($output -match 'ParserError|syntax error') { throw "Mutation $($mutation.Name) died from invalid syntax" }
        "Killed migration mutation $($mutation.Name): $($mutation.Assertion)"
    }
    "WslHomeSchedulingMigration semantic mutations killed: $($Mutations.Count)"
} finally {
    Remove-Item Env:WSL_HOME_MIGRATION_CANDIDATE -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue
}
