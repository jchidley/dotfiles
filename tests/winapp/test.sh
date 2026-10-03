#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
export HOME="$work/home"
mkdir -p "$HOME/.config/winapp" "$work/bin"
registry="$HOME/.config/winapp/apps.tsv"
launcher="$repo/dot_local/bin/executable_winapp"

# Conversion remains local to this disposable fixture; no Windows app is launched.
cat >"$work/bin/wslpath" <<'WSLPATH'
#!/usr/bin/env bash
[[ $2 == -- ]] || exit 1
case $1 in
  -w) printf 'C:\\fixture%s\n' "$3" ;;
  -u) printf '%s\n' "${3#C:\\fixture}" ;;
  *) exit 1 ;;
esac
WSLPATH
chmod +x "$work/bin/wslpath"
export PATH="$work/bin:$PATH"
: >"$registry"
output=$(bash "$launcher" --help)
[[ $output == *'winapp --list'* ]]
[[ $(bash "$launcher" --list) == *WINDOWS_EXECUTABLE* ]]
if bash "$launcher" --list extra >/dev/null 2>&1; then exit 1; fi
if bash "$launcher" --change unknown "$work/bin/missing.exe" >/dev/null 2>&1; then exit 1; fi
printf '#!/usr/bin/env bash\nexit 0\n' >"$work/bin/first.exe"
printf '#!/usr/bin/env bash\nexit 0\n' >"$work/bin/second.exe"
chmod +x "$work/bin/first.exe" "$work/bin/second.exe"
bash "$launcher" --add sample "$work/bin/first.exe" >/dev/null
[[ $(bash "$launcher" --list) == *'sample'*"C:\fixture$work/bin/first.exe"* ]]
if bash "$launcher" --add sample "$work/bin/first.exe" >/dev/null 2>&1; then exit 1; fi
bash "$launcher" --change sample "$work/bin/second.exe" >/dev/null
[[ $(bash "$launcher" --list) == *'sample'*"C:\fixture$work/bin/second.exe"* ]]
[[ $(stat -c %a "$registry") == 600 ]]
# Record launch arguments rather than entering Windows.
export LAUNCH_LOG="$work/launch.log"
for program in explorer.exe notepad.exe second.exe; do
  cat >"$work/bin/$program" <<'EXE'
#!/usr/bin/env bash
printf '%s\n' "${0##*/}" "$#" "$@" >"$LAUNCH_LOG"
EXE
  chmod +x "$work/bin/$program"
done
mkdir -p "$work/a folder" "$HOME/git/agent-skills/skills/windows-env"
touch "$work/a folder/file.txt"
cat >"$HOME/git/agent-skills/skills/windows-env/ps-exec" <<'PS_EXEC'
#!/usr/bin/env bash
[[ $1 == --stdin ]] || exit 1
# Consume the script but never invoke PowerShell or a real Windows application.
script=$(cat)
[[ $script == *'Test-Path -LiteralPath $file)'* ]] || exit 1
printf '%s\n' "$WINAPP_EXE" "$WINAPP_TARGET" >"$LAUNCH_LOG"
PS_EXEC

assert_launch() {
  local program=$1 count=$2 target=${3-}
  mapfile -t actual <"$LAUNCH_LOG"
  [[ ${actual[0]} == "$program" && ${actual[1]} == "$count" ]]
  if [[ $count == 1 ]]; then [[ ${actual[2]} == "$target" ]]; fi
}
bash "$launcher" -f
assert_launch explorer.exe 0
bash "$launcher" -f notepad.exe
assert_launch notepad.exe 0
bash "$launcher" -f notepad
assert_launch notepad.exe 0
bash "$launcher" -f sample
assert_launch second.exe 0
bash "$launcher" -f "$work/a folder"
assert_launch explorer.exe 1 "C:\fixture$work/a folder"
bash "$launcher" -f notepad.exe "$work/a folder/file.txt"
assert_launch notepad.exe 1 "C:\fixture$work/a folder/file.txt"
bash "$launcher" -f notepad.exe "C:\fixture$work/a folder/file.txt"
assert_launch notepad.exe 1 "C:\fixture$work/a folder/file.txt"
bash "$launcher" -f '' "$work/a folder"
assert_launch explorer.exe 1 "C:\fixture$work/a folder"
rm "$LAUNCH_LOG"
for args in path program windows; do
  case $args in
    path) set -- "$work/missing" ;;
    program) set -- notepad.exe "$work/missing" ;;
    windows) set -- notepad.exe "C:\fixture$work/missing" ;;
  esac
  if bash "$launcher" -f "$@" >"$work/error" 2>&1; then exit 1; fi
  [[ ! -e $LAUNCH_LOG ]]
  grep -q 'Path not found' "$work/error"
done
if bash "$launcher" -f nonexistent-program >/dev/null 2>&1; then exit 1; fi
if bash "$launcher" one two three >/dev/null 2>&1; then exit 1; fi
bash "$launcher" notepad.exe "$work/a folder"
mapfile -t actual <"$LAUNCH_LOG"
[[ ${actual[0]} == "C:\fixture$work/bin/notepad.exe" && ${actual[1]} == "C:\fixture$work/a folder" ]]
# Direct programs and Explorer do not require an app registry.
rm "$registry"
bash "$launcher" -f
assert_launch explorer.exe 0
bash "$launcher" -f notepad.exe
assert_launch notepad.exe 0
printf 'PASS: winapp registry, optional program/path, validation and conversion (fixture only)\n'
