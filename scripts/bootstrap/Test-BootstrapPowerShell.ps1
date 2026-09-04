#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$temp = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-bootstrap-ps-$([Guid]::NewGuid().ToString('N'))"
try {
    [void](New-Item -ItemType Directory -Path $temp)
    $config = Join-Path $temp 'vault.conf'
    [IO.File]::WriteAllText($config, "# test only`nwsl_distro=Source`n", [Text.UTF8Encoding]::new($false))
    $routeScript = Join-Path $PSScriptRoot 'Set-WindowsAkRoute.ps1'
    $preview = & $routeScript -TargetDistribution Target -ConfigPath $config | Out-String
    if ($preview -notmatch 'Preview only' -or (Get-Content -LiteralPath $config -Raw) -notmatch 'wsl_distro=Source') {
        throw 'Route preview changed state or omitted its preview marker.'
    }
    & $routeScript -TargetDistribution Target -ConfigPath $config -Execute | Out-Null
    if ((Get-Content -LiteralPath $config -Raw) -notmatch '(?m)^wsl_distro=Target$') { throw 'Route execution did not update the target.' }
    $backups = @(Get-ChildItem -LiteralPath $temp -Filter 'vault.conf.before-*')
    if ($backups.Count -ne 1 -or (Get-Content -LiteralPath $backups[0].FullName -Raw) -notmatch 'wsl_distro=Source') {
        throw 'Route execution did not preserve exactly one valid backup.'
    }

    $rootfs = Join-Path $temp 'rootfs.tar.gz'
    [IO.File]::WriteAllText($rootfs, 'preview-only-rootfs', [Text.UTF8Encoding]::new($false))
    $rootfsHash = (Get-FileHash -LiteralPath $rootfs -Algorithm SHA256).Hash
    $builder = Join-Path $PSScriptRoot 'New-BootstrappedDebianWsl.ps1'
    $buildPreview = & $builder -Distribution Debian3 -InstallPath (Join-Path $temp 'Debian3') -RootfsPath $rootfs -ExpectedRootfsSha256 $rootfsHash | Out-String
    if ($buildPreview -notmatch 'Preview only' -or $buildPreview -notmatch 'secrets: not copied') {
        throw 'Retained-distro builder preview contract failed.'
    }

    $copyScript = Join-Path $PSScriptRoot 'Copy-WslAkSecrets.ps1'
    $copyPreview = & $copyScript -SourceDistribution Source -SourceUser jack -TargetDistribution Target -TargetUser jack | Out-String
    if ($copyPreview -notmatch 'Preview only' -or $copyPreview -notmatch 'no archive is written to Windows') {
        throw 'Secret-copy preview contract failed.'
    }
    Write-Output 'Bootstrap PowerShell preview and route tests passed.'
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
