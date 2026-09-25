#!/usr/bin/env bash
# Open a registered Windows application from WSL, optionally with one file.
set -euo pipefail

registry="$HOME/.config/winapp/apps.tsv"
usage() {
  local status=${1:-2}
  local text='Usage: winapp [--foreground|-f|-fg] APP [FILE]
       winapp --list|-l
       winapp --add|-a APP EXE
       winapp --change|-c APP EXE
       winapp --help|-h

By default, launch APP on Windows and return immediately.
FILE is optional; APP and EXE paths are listed with --list.
EXE may be a Windows or WSL path to an existing .exe.'
  if (( status == 0 )); then printf '%s\n' "$text"; else printf '%s\n' "$text" >&2; fi
  exit "$status"
}
fail() { printf '%s\n' "$*" >&2; exit 1; }

# Translate a Windows path to WSL before checking it. Bash paths stay Bash paths.
to_linux() {
  local path=$1
  if [[ $path =~ ^[[:alpha:]]:[/\\] || $path == \\* ]]; then
    path=$(wslpath -u -- "$path")
  fi
  realpath -e -- "$path" 2>/dev/null
}

mode=detach
case ${1-} in
  --help|-h) usage 0 ;;
  --list|-l) mode=list; shift ;;
  --add|-a) mode=add; shift ;;
  --change|-c) mode=change; shift ;;
  --foreground|-f|-fg) mode=foreground; shift ;;
  --detach) shift ;; # Existing calls keep working; detach is now the default.
  -*) usage ;;
esac

case $mode in
  list) (( $# == 0 )) || usage ;;
  add|change) (( $# == 2 )) || usage ;;
  *) (( $# == 1 || $# == 2 )) || usage ;;
esac

if [[ $mode == add || $mode == change ]]; then
  [[ $1 =~ ^[a-z][a-z0-9-]*$ ]] || fail 'App name must start with a lowercase letter and contain only lowercase letters, digits, or hyphens'
  exe_linux=$(to_linux "$2") && [[ -f $exe_linux && -x $exe_linux && ${exe_linux,,} == *.exe ]] || fail "Windows .exe not found or not executable: $2"
  new_exe=$(wslpath -w -- "$exe_linux")
  [[ $new_exe != *$'\t'* && $new_exe != *$'\n'* && $new_exe != *$'\r'* ]] || fail 'Executable path cannot contain tabs or line breaks'
  # Serialize registry edits; atomic replacement avoids partial files.
  exec {lock_fd}>"${registry}.lock"
  flock -x "$lock_fd"
fi

[[ -f $registry ]] || fail "Registry missing: $registry"
declare -A apps=()
declare -a names=()
while IFS= read -r line || [[ -n $line ]]; do
  [[ $line == *$'\t'* ]] || fail "Malformed registry entry: $line"
  key=${line%%$'\t'*}
  value=${line#*$'\t'}
  [[ $key =~ ^[a-z][a-z0-9-]*$ && -n $value && $value != *$'\t'* && $value != *$'\r'* ]] || fail "Malformed registry entry: $line"
  [[ ! -v apps[$key] ]] || fail "Duplicate app in registry: $key"
  apps["$key"]=$value
  names+=("$key")
done < "$registry"

case $mode in
  list)
    printf '%-12s %s\n' APP WINDOWS_EXECUTABLE
    for key in "${names[@]}"; do printf '%-12s %s\n' "$key" "${apps[$key]}"; done
    exit 0 ;;
  add|change)
    if [[ $mode == add && -v apps[$1] ]]; then fail "App already exists: $1 (use --change)"; fi
    if [[ $mode == change && ! -v apps[$1] ]]; then fail "Unknown app: $1 (use --add)"; fi
    umask 077
    tmp=$(mktemp "${registry}.XXXXXX")
    trap 'rm -f -- "$tmp"' EXIT
    for key in "${names[@]}"; do
      if [[ $mode == change && $key == "$1" ]]; then
        printf '%s\t%s\n' "$key" "$new_exe" >> "$tmp"
      else
        printf '%s\t%s\n' "$key" "${apps[$key]}" >> "$tmp"
      fi
    done
    if [[ $mode == add ]]; then printf '%s\t%s\n' "$1" "$new_exe" >> "$tmp"; fi
    mv -f -- "$tmp" "$registry"
    trap - EXIT
    printf '%s: %s -> %s\n' "${mode^}" "$1" "$new_exe"
    exit 0 ;;
esac

app=$1
[[ $app =~ ^[a-z][a-z0-9-]*$ ]] || fail "Unknown app: $app (run winapp --list)"
[[ -v apps[$app] ]] || fail "Unknown app: $app (run winapp --list)"
exe_windows=${apps[$app]}
exe_linux=$(to_linux "$exe_windows") && [[ -f $exe_linux && -x $exe_linux ]] || fail "Executable not found: $exe_windows"
target=''
if (( $# == 2 )); then
  linux_file=$(to_linux "$2") && [[ -f $linux_file ]] || fail "File not found: $2"
  target=$(wslpath -w -- "$linux_file")
fi

if [[ $mode == detach ]]; then
  # Start-Process needs quoted argv for paths with spaces. Double quotes are
  # not legal in Windows filenames; reject them if a WSL path contains one.
  [[ $target != *\"* ]] || fail "Cannot pass a file with a double quote to Start-Process: $2"
  WSLENV="${WSLENV:+$WSLENV:}WINAPP_EXE:WINAPP_TARGET" \
  WINAPP_EXE="$exe_windows" WINAPP_TARGET="$target" \
  bash "$HOME/git/agent-skills/skills/windows-env/ps-exec" --stdin <<'POWERSHELL'
$ErrorActionPreference = 'Stop'
$exe = $env:WINAPP_EXE
$file = $env:WINAPP_TARGET
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw "Executable not reachable: $exe" }
if ($file) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "File not reachable from Windows: $file" }
    $p = Start-Process -FilePath $exe -ArgumentList ('"' + $file + '"') -PassThru
} else {
    $p = Start-Process -FilePath $exe -PassThru
}
Write-Output "Launched $($p.ProcessName) (Windows PID $($p.Id))"
POWERSHELL
else
  if [[ -n $target ]]; then "$exe_linux" "$target"; else "$exe_linux"; fi
fi
