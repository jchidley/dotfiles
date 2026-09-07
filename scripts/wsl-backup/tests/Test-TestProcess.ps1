#requires -Version 7.0
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
. (Join-Path $PSScriptRoot 'TestProcess.Common.ps1')
$root = Join-Path ([IO.Path]::GetTempPath()) ('wsl-process-fixture-' + [guid]::NewGuid())
$null = New-Item -ItemType Directory -Path $root
function Invoke-Fixture {
    param([string] $Path, [int] $Deadline)
    $psi = [Diagnostics.ProcessStartInfo]::new((Get-Command pwsh.exe -CommandType Application | Select-Object -First 1).Source)
    foreach ($arg in @('-NoProfile', '-NonInteractive', '-File', $Path)) { $psi.ArgumentList.Add($arg) }
    Invoke-BoundedTestProcess -StartInfo $psi -Name $Path -TimeoutMilliseconds $Deadline
}
try {
    $heavy = Join-Path $root 'heavy.ps1'
    Set-Content -LiteralPath $heavy -Value @'
[Console]::Error.Write(('E' * 262144))
[Console]::Out.Write('stdout-complete')
exit 7
'@
    $result = Invoke-Fixture $heavy 15000
    if ($result.ExitCode -ne 7 -or $result.Stdout -ne 'stdout-complete' -or $result.Stderr.Length -ne 262144) { throw 'Concurrent pipe drain or exit propagation failed' }
    if ([IO.File]::ReadAllText((Join-Path $result.LogDirectory 'stderr.log')).Length -ne 262144) { throw 'Failure log was not preserved' }
    $hang = Join-Path $root 'hang.ps1'
    Set-Content -LiteralPath $hang -Value @'
[Console]::Out.WriteLine('before-hang')
[Console]::Error.WriteLine('diagnostic-before-hang')
Start-Sleep -Seconds 300
'@
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $failure = ''
    try { Invoke-Fixture $hang 2000 | Out-Null } catch { $failure = $_.Exception.Message }
    if ($failure -notmatch 'Child timed out:.*logs=(.+)$') { throw "Hanging child not attributed: $failure" }
    $logs = $Matches[1]
    if ($clock.Elapsed.TotalSeconds -gt 12) { throw 'Deadline did not bound the wait' }
    if ([IO.File]::ReadAllText((Join-Path $logs 'stdout.log')) -notmatch 'before-hang') { throw 'Timeout lost stdout' }
    if ([IO.File]::ReadAllText((Join-Path $logs 'stderr.log')) -notmatch 'diagnostic-before-hang') { throw 'Timeout lost stderr' }
    $tree = Join-Path $root 'tree.ps1'
    Set-Content -LiteralPath $tree -Value @'
$psi = [Diagnostics.ProcessStartInfo]::new((Get-Command pwsh.exe).Source)
$psi.UseShellExecute = $false
foreach ($arg in @('-NoProfile', '-NonInteractive', '-File', (Join-Path $PSScriptRoot 'hang.ps1'))) { $psi.ArgumentList.Add($arg) }
$child = [Diagnostics.Process]::Start($psi)
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'descendant.pid'), [string]$child.Id)
Start-Sleep -Seconds 300
'@
    $failure = ''
    try { Invoke-Fixture $tree 3000 | Out-Null } catch { $failure = $_.Exception.Message }
    if ($failure -notmatch 'Child timed out:') { throw 'Process-tree deadline did not fire' }
    $descendantId = [int][IO.File]::ReadAllText((Join-Path $root 'descendant.pid'))
    if (Get-Process -Id $descendantId -ErrorAction SilentlyContinue) { throw "Test descendant survived: $descendantId" }
    Write-Output 'Bounded test-process tests passed: concurrent pipes, exit status, real deadline, process-tree termination, preserved diagnostics.'
} finally {
    Remove-Item -LiteralPath $root -Recurse -Force
}
