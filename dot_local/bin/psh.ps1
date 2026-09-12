#requires -Version 7.0

$canonicalScript = Join-Path $HOME 'git/agent-skills/skills/pi-session-history/scripts/psh.mjs'
$launcherName = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$nodeCommand = Get-Command -Name node -CommandType Application -ErrorAction SilentlyContinue

if ($null -eq $nodeCommand) {
    [Console]::Error.WriteLine("${launcherName}: node is required but was not found in PATH")
    exit 1
}

if (-not (Test-Path -LiteralPath $canonicalScript -PathType Leaf)) {
    [Console]::Error.WriteLine("${launcherName}: canonical psh script not found: $canonicalScript")
    exit 1
}

$nodePath = $nodeCommand.Source
& $nodePath $canonicalScript @args
exit $LASTEXITCODE
