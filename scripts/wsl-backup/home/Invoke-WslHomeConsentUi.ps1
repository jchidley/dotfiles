#requires -Version 7.0
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost','',
    Justification='The interactive consent UI must display factual prompt text without adding it to JSON output.')]
param(
    [Parameter(Mandatory = $true)][ValidateSet('Probe','Prompt')][string] $Action,
    [string] $PromptPath,
    [ValidateRange(1,3600)][int] $TimeoutSeconds = 300
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
if ($PSVersionTable.PSEdition -ne 'Core') { throw 'PowerShell 7 is required' }
$interactive = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
if ($Action -eq 'Probe') {
    [ordered]@{Interactive=$interactive} | ConvertTo-Json -Compress
    exit 0
}
if (-not $interactive) { [ordered]@{Decision='Ignored'} | ConvertTo-Json -Compress; exit 0 }
if ([string]::IsNullOrWhiteSpace($PromptPath) -or -not (Test-Path -LiteralPath $PromptPath -PathType Leaf)) {
    throw 'Prompt requires a factual prompt document'
}
$prompt = Get-Content -LiteralPath $PromptPath -Raw | ConvertFrom-Json -ErrorAction Stop
[Console]::Error.WriteLine()
[Console]::Error.WriteLine('WSL backup maintenance')
[Console]::Error.WriteLine()
[Console]::Error.WriteLine([string]$prompt.DisplayName)
[Console]::Error.WriteLine(("Reason: {0}" -f $prompt.DueReason))
[Console]::Error.WriteLine(("Power: {0}" -f $prompt.Power))
[Console]::Error.WriteLine(("Effect: {0}" -f $prompt.Effect))
if ($null -ne $prompt.LastSuccessfulCompletion) {
    [Console]::Error.WriteLine(("Last successful completion: {0}" -f $prompt.LastSuccessfulCompletion))
}
if ($null -ne $prompt.PreviousResult) {
    [Console]::Error.WriteLine(("Previous result: {0}" -f $prompt.PreviousResult))
}
if ($null -ne $prompt.PreviousDurationSeconds) {
    [Console]::Error.WriteLine(("Previous measured duration: {0} seconds" -f $prompt.PreviousDurationSeconds))
}
if ($null -ne $prompt.ConservativeDurationSeconds) {
    [Console]::Error.WriteLine(("Conservative duration evidence: {0} seconds" -f $prompt.ConservativeDurationSeconds))
}
[Console]::Error.WriteLine()
[Console]::Error.WriteLine('Run it now? Type Yes or No:')
$readTask = [System.Threading.Tasks.Task[string]]::Run([Func[string]]{ [Console]::ReadLine() })
if (-not $readTask.Wait([timespan]::FromSeconds($TimeoutSeconds))) {
    [ordered]@{Decision='TimedOut'} | ConvertTo-Json -Compress
    exit 0
}
$answer = $readTask.Result
$decision = if ($answer -match '^\s*y(es)?\s*$') { 'Yes' } elseif ($answer -match '^\s*n(o)?\s*$') { 'No' } else { 'Ignored' }
[ordered]@{Decision=$decision} | ConvertTo-Json -Compress
