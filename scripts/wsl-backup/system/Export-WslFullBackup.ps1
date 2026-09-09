#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$Distro = 'Debian4',
    [string]$OutputDirectory = 'C:\WSL-Backups\Debian4\full'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Get-WslNames([switch]$Running) {
    $arguments = @('--list','--quiet')
    if ($Running) { $arguments = @('--list','--running','--quiet') }
    $lines = @(& wsl.exe @arguments)
    if ($LASTEXITCODE -ne 0) { throw 'WSL inventory failed' }
    @($lines | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
}
if ($Distro -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { throw 'Invalid distro name' }
if ($Distro -notin @(Get-WslNames)) { throw 'Requested distro is not registered' }
if ($Distro -in @(Get-WslNames -Running)) { throw 'Stop the distro in an approved maintenance window before exporting; no automatic termination is performed' }
$directory = [IO.Path]::GetFullPath($OutputDirectory)
if ($directory -notmatch '^[A-Za-z]:\\') { throw 'Destination must be on a Windows local drive, outside WSL' }
# Reject redirection into a source filesystem or an unexpected disk.
$ancestor = $directory
while ($ancestor) {
    if (Test-Path -LiteralPath $ancestor) {
        $item = Get-Item -LiteralPath $ancestor -Force
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Destination contains a redirected or non-directory component' }
    }
    $ancestor = Split-Path -Parent $ancestor
}
$generation = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$partial = Join-Path $directory "$generation.partial"
$final = Join-Path $directory $generation
New-Item -ItemType Directory -Path $partial | Out-Null
$archive = Join-Path $partial 'rootfs.tar.gz'
# No exclusions or filtering: use WSL's complete root-filesystem export.
& wsl.exe --export $Distro $archive --format tar.gz
if ($LASTEXITCODE -ne 0) { throw "WSL export failed; partial evidence retained at $partial" }
if ($Distro -in @(Get-WslNames -Running)) { throw "Distro was started during capture; generation remains partial at $partial" }
$stream = [IO.File]::OpenRead($archive)
try { if ($stream.ReadByte() -ne 31 -or $stream.ReadByte() -ne 139) { throw 'Export is not gzip' } }
finally { $stream.Dispose() }
# Drain the full archive listing without logging its private filenames.
& tar.exe -tzf $archive | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Archive listing failed; partial retained at $partial" }
$manifest = [ordered]@{
    schemaVersion=1; format='wsl-full-tar.gz'; distro=$Distro
    completedUtc=(Get-Date).ToUniversalTime().ToString('o')
    archive='rootfs.tar.gz'; bytes=(Get-Item -LiteralPath $archive).Length
    sha256=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    exclusions=@(); sourceState='stopped'; restoreTested=$false
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $partial 'manifest.json') -Encoding utf8NoBOM
[IO.Directory]::Move($partial,$final)
Write-Output "full_export_completed=$final"
