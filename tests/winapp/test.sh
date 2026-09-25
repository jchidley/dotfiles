#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
export HOME="$work/home"
mkdir -p "$HOME/.config/winapp" "$work/bin"
registry="$HOME/.config/winapp/apps.tsv"
launcher="$repo/dot_local/bin/executable_winapp-open.sh"

# Conversion remains local to this disposable fixture; no Windows app is launched.
cat >"$work/bin/wslpath" <<'WSLPATH'
#!/usr/bin/env bash
[[ $1 == -w && $2 == -- ]] || exit 1
printf 'C:\\fixture\\%s\n' "${3##*/}"
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
[[ $(bash "$launcher" --list) == *'sample'*'C:\fixture\first.exe'* ]]
if bash "$launcher" --add sample "$work/bin/first.exe" >/dev/null 2>&1; then exit 1; fi
bash "$launcher" --change sample "$work/bin/second.exe" >/dev/null
[[ $(bash "$launcher" --list) == *'sample'*'C:\fixture\second.exe'* ]]
[[ $(stat -c %a "$registry") == 600 ]]
printf 'PASS: winapp help, list, add, change and duplicate refusal (fixture only)\n'
