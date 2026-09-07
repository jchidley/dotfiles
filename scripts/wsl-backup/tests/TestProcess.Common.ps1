#requires -Version 7.0

function Invoke-BoundedTestProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][Diagnostics.ProcessStartInfo] $StartInfo,
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][ValidateRange(1, 3600000)][int] $TimeoutMilliseconds
    )
    $StartInfo.UseShellExecute = $false
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $StartInfo
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $timedOut = $false
    try {
        $null = $process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        [Console]::Error.WriteLine("test_start name=$Name pid=$($process.Id) deadline_ms=$TimeoutMilliseconds")
        $nextProgress = 10000
        while (-not $process.WaitForExit(100)) {
            if ($clock.ElapsedMilliseconds -ge $TimeoutMilliseconds) {
                $timedOut = $true
                $process.Kill($true)
                if (-not $process.WaitForExit(5000)) { throw "Test process tree did not terminate: $Name pid=$($process.Id)" }
                break
            }
            if ($clock.ElapsedMilliseconds -ge $nextProgress) {
                [Console]::Error.WriteLine("test_running name=$Name pid=$($process.Id) elapsed_ms=$($clock.ElapsedMilliseconds)")
                $nextProgress += 10000
            }
        }
        # Descendants retaining pipe handles must not create another unbounded wait.
        $drained = [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdoutTask, $stderrTask), 5000)
        $stdout = if ($stdoutTask.IsCompletedSuccessfully) { $stdoutTask.GetAwaiter().GetResult() } else { '[stdout pipe did not close]' }
        $stderr = if ($stderrTask.IsCompletedSuccessfully) { $stderrTask.GetAwaiter().GetResult() } else { '[stderr pipe did not close]' }
        $exitCode = $process.ExitCode
        [Console]::Error.WriteLine("test_end name=$Name pid=$($process.Id) elapsed_ms=$($clock.ElapsedMilliseconds) exit=$exitCode timeout=$timedOut")
        $logDirectory = $null
        if ($timedOut -or -not $drained -or $exitCode -ne 0) {
            $logDirectory = Join-Path ([IO.Path]::GetTempPath()) ('wsl-test-process-' + [guid]::NewGuid())
            $null = New-Item -ItemType Directory -Path $logDirectory
            [IO.File]::WriteAllText((Join-Path $logDirectory 'stdout.log'), $stdout)
            [IO.File]::WriteAllText((Join-Path $logDirectory 'stderr.log'), $stderr)
            [Console]::Error.WriteLine("test_logs name=$Name path=$logDirectory")
        }
        if ($timedOut) { throw "Child timed out: $Name; logs=$logDirectory" }
        if (-not $drained) { throw "Child output pipes did not close: $Name; logs=$logDirectory" }
        [pscustomobject]@{ ExitCode=$exitCode; Stdout=$stdout.Trim(); Stderr=$stderr.Trim(); Text="$stdout`n$stderr"; LogDirectory=$logDirectory }
    } finally {
        $clock.Stop()
        $process.Dispose()
    }
}
