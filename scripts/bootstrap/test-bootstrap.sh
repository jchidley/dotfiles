#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bootstrap="$root/debian-bootstrap-safe.sh"
secret_helper="$root/migrate-ak-secrets.sh"
template="$root/../../run_onchange_after_20-wsl-config.sh.tmpl"

bash -n "$bootstrap" "$secret_helper"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x "$bootstrap" "$secret_helper"
fi

! grep -q 'releases/latest' "$bootstrap"
! grep -q 'fnm install --lts --use' "$bootstrap"
! grep -q 'git@github.com' "$bootstrap"
! grep -q 'mkdir -p .*HOME/tools' "$bootstrap"
grep -q 'XDG_RUNTIME_DIR/fnm_multishells' "$bootstrap"
grep -q 'DOTFILES_APPLY_WSL_INTEGRATION' "$template"
grep -q 'https://github.com/${repository}.git' "$bootstrap"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home"
manifest="$tmp/workspace-repos.tsv"
cat >"$manifest" <<'EOF'
# group	kind	repository	destination	profiles
foundation	git	example/tools	~/tools	all
EOF
run_clean_home() {
  HOME="$tmp/home" \
  WORKSPACE_MANIFEST="$manifest" \
  BOOTSTRAP_DRY_RUN=1 \
  SKIP_SYSTEM_PACKAGES=1 \
  APPLY_CHEZMOI=0 \
  bash "$bootstrap"
}
first=$(run_clean_home 2>&1)
second=$(run_clean_home 2>&1)
for output in "$first" "$second"; do
  grep -q 'install chezmoi 2.69.4' <<<"$output"
  grep -q 'install fnm 1.38.1 and Node v22.19.0' <<<"$output"
  grep -q 'install Pi 0.85.0' <<<"$output"
  grep -q 'git clone https://github.com/example/tools.git' <<<"$output"
  grep -q 'Bootstrap complete' <<<"$output"
done
[[ ! -e "$tmp/home/tools" ]]

# Exercise the secret-transfer allowlist and target backup without real secrets.
mkdir -p "$tmp/bin" "$tmp/source/.gnupg/private-keys-v1.d" "$tmp/source/.config/ak" \
  "$tmp/source/git/ak/secrets" "$tmp/target/.config/ak"
printf '#!/usr/bin/env bash\nexit 0\n' >"$tmp/bin/gpg"
chmod 0755 "$tmp/bin/gpg"
printf key >"$tmp/source/.gnupg/private-keys-v1.d/test.key"
printf 'wsl_distro=Source\n' >"$tmp/source/.config/ak/vault.conf"
printf encrypted >"$tmp/source/git/ak/secrets/brave.gpg"
printf key-id >"$tmp/source/git/ak/.gpg-key-id"
printf old-route >"$tmp/target/.config/ak/vault.conf"
PATH="$tmp/bin:$PATH" HOME="$tmp/source" bash "$secret_helper" export >"$tmp/transfer.tar"
PATH="$tmp/bin:$PATH" HOME="$tmp/target" AK_TARGET_DISTRIBUTION=Target bash "$secret_helper" import --execute <"$tmp/transfer.tar" >/dev/null
[[ $(<"$tmp/target/git/ak/secrets/brave.gpg") == encrypted ]]
[[ $(<"$tmp/target/git/ak/.gpg-key-id") == key-id ]]
grep -qx 'wsl_distro=Target' "$tmp/target/.config/ak/vault.conf"
if [[ $(uname -s) != MINGW* ]]; then
  [[ $(stat -c %a "$tmp/target/.gnupg/private-keys-v1.d/test.key") == 600 ]]
fi
grep -R -q old-route "$tmp/target/.local/state/dotfiles-secret-migrations"/backup-*/home/.config/ak/vault.conf
mkdir "$tmp/malicious"
tar -xf "$tmp/transfer.tar" -C "$tmp/malicious"
printf bad >"$tmp/malicious/not-allowed"
tar -C "$tmp/malicious" -cf "$tmp/malicious.tar" .
if PATH="$tmp/bin:$PATH" HOME="$tmp/target" AK_TARGET_DISTRIBUTION=Target bash "$secret_helper" import --execute <"$tmp/malicious.tar" >/dev/null 2>&1; then
  echo 'Secret migration accepted a non-allowlisted archive member.' >&2
  exit 1
fi

echo 'Bootstrap clean-home, secret migration, and static regression tests passed.'
