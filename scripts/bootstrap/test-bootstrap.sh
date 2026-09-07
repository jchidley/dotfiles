#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bootstrap="$root/debian-bootstrap-safe.sh"
secret_helper="$root/migrate-ak-secrets.sh"
bash_custom="$root/../../dot_bashrc_custom"
web_search="$root/../../bin/executable_web-search"
template="$root/../../run_onchange_after_20-wsl-config.sh.tmpl"
terminal_linux_template="$root/../../run_onchange_after_50-windows-terminal.sh.tmpl"
terminal_windows_template="$root/../../run_onchange_after_50-windows-terminal.ps1.tmpl"

bash -n "$bootstrap" "$secret_helper" "$bash_custom" "$web_search" "$root/setup-rust.sh"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x "$bootstrap" "$secret_helper" "$root/setup-rust.sh"
fi

! grep -q 'releases/latest' "$bootstrap"
! grep -q 'fnm install --lts --use' "$bootstrap"
! grep -q 'git@github.com' "$bootstrap"
! grep -q 'mkdir -p .*HOME/tools' "$bootstrap"
grep -q 'XDG_RUNTIME_DIR/fnm_multishells' "$bootstrap"
grep -q 'native fnm-managed Pi is unavailable' "$bootstrap"
grep -q 'DOTFILES_APPLY_WSL_INTEGRATION' "$template"
grep -q 'DOTFILES_APPLY_WSL_INTEGRATION' "$terminal_linux_template"
grep -q 'DOTFILES_APPLY_WSL_INTEGRATION' "$terminal_windows_template"
grep -q 'https://github.com/${repository}.git' "$bootstrap"
for package in build-essential mold rustup fd-find gh git-delta neovim ripgrep; do
  grep -Eq "apt-get install .* ${package}( |$)" "$bootstrap"
done
grep -q 'install_uv' "$bootstrap"
grep -q 'DOTFILES_WORKSPACE=.*git/dotfiles' "$bootstrap"
grep -q 'BOOTSTRAP_SETUP_AK=0' "$root/New-BootstrappedDebianWsl.ps1"
grep -q 'BOOTSTRAP_SETUP_AK=0' "$root/Test-PristineDebianBootstrap.ps1"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home/git/ak/bin" "$tmp/home/.local/share/chezmoi/.git"
printf '#!/usr/bin/env bash\nexit 0\n' >"$tmp/home/git/ak/bin/ak"
chmod 0755 "$tmp/home/git/ak/bin/ak"
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
  grep -q 'install uv 0.8.18' <<<"$output"
  grep -q 'configure native Cargo mold default' <<<"$output"
  grep -q 'ln -sfn /usr/bin/fdfind .*\.local/bin/fd' <<<"$output"
  grep -q 'git clone https://github.com/example/tools.git' <<<"$output"
  grep -q 'standard passphrase-protected GPG identity' <<<"$output"
  grep -q 'ln -sfn .*\.local/share/chezmoi .*git/dotfiles' <<<"$output"
  grep -q 'Bootstrap complete' <<<"$output"
done
[[ ! -e "$tmp/home/tools" ]]

# Exercise the actual top-level set -e caller, not setup_ak in a conditional
# (which would suppress errexit inside the function). Both skips must finish.
BOOTSTRAP_SETUP_AK=0 run_clean_home >"$tmp/ak-disabled.log" 2>&1
grep -q 'Bootstrap complete' "$tmp/ak-disabled.log"
! grep -q 'standard passphrase-protected GPG identity' "$tmp/ak-disabled.log"
chmod 0644 "$tmp/home/git/ak/bin/ak"
BOOTSTRAP_SETUP_AK=1 run_clean_home >"$tmp/ak-not-executable.log" 2>&1
grep -q 'Bootstrap complete' "$tmp/ak-not-executable.log"
! grep -q 'standard passphrase-protected GPG identity' "$tmp/ak-not-executable.log"
rm "$tmp/home/git/ak/bin/ak"
BOOTSTRAP_SETUP_AK=1 run_clean_home >"$tmp/ak-missing.log" 2>&1
grep -q 'Bootstrap complete' "$tmp/ak-missing.log"
! grep -q 'standard passphrase-protected GPG identity' "$tmp/ak-missing.log"

# Never replace operator Cargo settings, including the legacy config filename.
mkdir -p "$tmp/home/.cargo"
printf 'operator config\n' >"$tmp/home/.cargo/config.toml"
if HOME="$tmp/home" BOOTSTRAP_DRY_RUN=1 bash "$root/setup-rust.sh"; then
  echo 'Rust setup accepted conflicting Cargo configuration.' >&2; exit 1
fi
grep -qx 'operator config' "$tmp/home/.cargo/config.toml"
mv "$tmp/home/.cargo/config.toml" "$tmp/home/.cargo/config"
if HOME="$tmp/home" BOOTSTRAP_DRY_RUN=1 bash "$root/setup-rust.sh"; then
  echo 'Rust setup accepted legacy Cargo configuration.' >&2; exit 1
fi

grep -qx 'operator config' "$tmp/home/.cargo/config"

# Exercise Rust setup with disposable state and commands, never real rustup.
rust_home="$tmp/rust-home"
rust_bin="$tmp/rust-bin"
mkdir -p "$rust_home" "$rust_bin"
cat >"$rust_bin/rustup" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$HOME/rustup.calls"
case "$*" in
  'run stable rustc --version'|'run stable cargo --version') [[ -f "$HOME/stable-installed" ]] ;;
  'toolchain install stable --profile minimal') touch "$HOME/stable-installed" ;;
  'default stable') [[ -f "$HOME/stable-installed" ]] ;;
  *) echo "Unexpected rustup call: $*" >&2; exit 1 ;;
esac
EOF
printf '#!/usr/bin/env bash\nexit 0\n' >"$rust_bin/cc"
cp "$rust_bin/cc" "$rust_bin/mold"
chmod 0755 "$rust_bin/"*
run_rust() {
  HOME="$rust_home" CARGO_HOME= RUSTUP_HOME="$rust_home/.rustup" \
    PATH="$rust_bin:$PATH" BOOTSTRAP_DRY_RUN=0 BOOTSTRAP_OFFLINE="$1" \
    bash "$root/setup-rust.sh"
}
if run_rust 1; then
  echo 'Offline Rust setup accepted a missing stable toolchain.' >&2; exit 1
fi
[[ ! -e "$rust_home/.cargo/config.toml" ]]
! grep -Eq '^(toolchain install|default)' "$rust_home/rustup.calls"
run_rust 0
grep -qx 'toolchain install stable --profile minimal' "$rust_home/rustup.calls"
grep -qx 'default stable' "$rust_home/rustup.calls"
printf '%s\n' '[target.x86_64-unknown-linux-gnu]' 'linker = "cc"' \
  'rustflags = ["-C", "link-arg=-fuse-ld=mold"]' >"$tmp/expected-cargo.toml"
cmp "$tmp/expected-cargo.toml" "$rust_home/.cargo/config.toml"
: >"$rust_home/rustup.calls"
run_rust 1
run_rust 0
! grep -q '^toolchain install' "$rust_home/rustup.calls"
cmp "$tmp/expected-cargo.toml" "$rust_home/.cargo/config.toml"
printf 'operator config\n' >"$rust_home/.cargo/config.toml"
: >"$rust_home/rustup.calls"
if run_rust 0; then
  echo 'Rust setup changed a conflicting configuration.' >&2; exit 1
fi
[[ ! -s "$rust_home/rustup.calls" ]]
grep -qx 'operator config' "$rust_home/.cargo/config.toml"
if HOME="$rust_home" CARGO_HOME="$tmp/custom-cargo" BOOTSTRAP_DRY_RUN=1 \
    bash "$root/setup-rust.sh"; then
  echo 'Rust setup accepted a custom CARGO_HOME.' >&2; exit 1
fi

# A fresh shell profile must create, but never truncate, Bash history before
# McFly initialization. Stub only the path helpers supplied by dot_bashrc.tmpl.
shell_home="$tmp/shell-home"
mkdir -p "$shell_home"
(
  HOME="$shell_home"
  HISTFILE="$shell_home/.bash_history"
  export XDG_DATA_HOME="$shell_home/.local/share"
  path_prepend() { :; }
  path_append() { :; }
  # shellcheck source=../../dot_bashrc_custom
  source "$bash_custom"
)
[[ -f "$shell_home/.bash_history" ]]
[[ $(stat -c %a "$shell_home/.bash_history") == 600 ]]
printf 'retained-history\n' >"$shell_home/.bash_history"
(
  HOME="$shell_home"
  HISTFILE="$shell_home/.bash_history"
  export XDG_DATA_HOME="$shell_home/.local/share"
  path_prepend() { :; }
  path_append() { :; }
  # shellcheck source=../../dot_bashrc_custom
  source "$bash_custom"
)
grep -qx 'retained-history' "$shell_home/.bash_history"
grep -Fqx 'exec node "$HOME/git/agent-skills/skills/web-search/web-search.mjs" "$@"' "$web_search"

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
