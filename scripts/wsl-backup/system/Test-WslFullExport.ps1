#requires -Version 7.0
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$token = [guid]::NewGuid().ToString('N')
$state = Join-Path $env:LOCALAPPDATA "WslFullExportTests\$token"
New-Item -ItemType Directory -Path $state | Out-Null
$sourceName = "FullExportTest-$token"
$restoreName = "FullRestoreTest-$token"
$transport = Join-Path $env:USERPROFILE 'git/agent-skills/skills/windows-env/Invoke-WslExec.ps1'
$linuxState = '/mnt/' + $state.Substring(0,1).ToLowerInvariant() + $state.Substring(2).Replace('\','/')
$prepare = @'
set -euo pipefail
root=$(mktemp -d /var/tmp/full-export-seed.XXXXXX)
mkdir -p "$root/bin" "$root/etc" "$root/root" "$root/home/jack" "$root/var/lib/restic/home" "$root/var/tmp"
cp /bin/bash "$root/bin/bash"
while read -r library; do cp --parents -L "$library" "$root"; done < <(ldd /bin/bash | grep -oE '/[^ ]+' | sort -u)
ln -s bash "$root/bin/sh"
printf 'root:x:0:0:root:/root:/bin/bash\n' >"$root/etc/passwd"
printf '[boot]\nsystemd=false\n[interop]\nenabled=false\nappendWindowsPath=false\n[automount]\nenabled=false\nmountFsTab=false\n[user]\ndefault=root\n' >"$root/etc/wsl.conf"
printf 'home-included\n' >"$root/home/jack/fixture"
printf 'repository-included\n' >"$root/var/lib/restic/home/config"
printf 'staging-included\n' >"$root/var/tmp/fixture"
tar -cf '__STATE__/seed.tar' -C "$root" .
printf 'seed=%s\n' "$root"
'@
& $transport -Distribution Debian4 -Script $prepare.Replace('__STATE__',$linuxState)
if ($LASTEXITCODE -ne 0) { throw 'Synthetic seed preparation failed' }
& wsl.exe --import $sourceName (Join-Path $state 'source') (Join-Path $state 'seed.tar') --version 2
if ($LASTEXITCODE -ne 0) { throw 'Synthetic source import failed' }
& (Join-Path $PSScriptRoot 'Export-WslFullBackup.ps1') -Distro $sourceName -OutputDirectory (Join-Path $state 'exports')
$generation = @(Get-ChildItem (Join-Path $state 'exports') -Directory | Where-Object Name -NotLike '*.partial')
if ($generation.Count -ne 1) { throw 'Expected one completed generation' }
$archive = Join-Path $generation[0].FullName 'rootfs.tar.gz'
$manifest = Get-Content (Join-Path $generation[0].FullName 'manifest.json') -Raw | ConvertFrom-Json
if ($manifest.sha256 -ne (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant() -or $manifest.exclusions.Count -ne 0) { throw 'Manifest mismatch' }
& wsl.exe --import $restoreName (Join-Path $state 'restored') $archive --version 2
if ($LASTEXITCODE -ne 0) { throw 'Compressed import failed' }
try {
    $verify = @'
set -euo pipefail
IFS= read -r home </home/jack/fixture
IFS= read -r repository </var/lib/restic/home/config
IFS= read -r staging </var/tmp/fixture
[[ $home == home-included && $repository == repository-included && $staging == staging-included ]]
printf 'full_export_import_boot=passed home=true repository=true staging=true\n'
'@
    & $transport -Distribution $restoreName -Script $verify
    if ($LASTEXITCODE -ne 0) { throw 'Synthetic restored boot/content verification failed' }
} finally {
    & wsl.exe --terminate $restoreName
    if ($LASTEXITCODE -ne 0) { throw 'Fixture stop failed' }
}
Write-Output "retained_fixture=$state source=$sourceName restored=$restoreName"
