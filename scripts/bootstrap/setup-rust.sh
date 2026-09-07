#!/usr/bin/env bash
set -euo pipefail

# Native Debian x86-64 development baseline. Keep cross-target linkers untouched.
[[ $(uname -m) == x86_64 ]] || { echo 'Rust setup supports x86-64 only.' >&2; exit 1; }
[[ $EUID -ne 0 ]] || { echo 'Run Rust setup as the target user, not root.' >&2; exit 1; }
[[ -z ${CARGO_HOME:-} || $CARGO_HOME == "$HOME/.cargo" ]] || { echo 'Custom CARGO_HOME requires manual review.' >&2; exit 1; }
config="$HOME/.cargo/config.toml"
expected='[target.x86_64-unknown-linux-gnu]
linker = "cc"
rustflags = ["-C", "link-arg=-fuse-ld=mold"]'
# Refuse conflicts before installing or changing a default toolchain.
[[ ! -e "$HOME/.cargo/config" ]] || { echo 'Existing ~/.cargo/config requires manual reconciliation.' >&2; exit 1; }
if [[ -e "$config" ]] && [[ $(<"$config") != "$expected" ]]; then
  echo 'Existing Cargo config.toml requires manual reconciliation; not overwritten.' >&2
  exit 1
fi
if [[ ${BOOTSTRAP_DRY_RUN:-0} == 1 ]]; then
  echo 'DRY-RUN: install stable Rust (minimal profile) and configure native Cargo mold default'
  exit 0
fi
for tool in rustup cc mold; do
  command -v "$tool" >/dev/null || { echo "Required tool missing: $tool" >&2; exit 1; }
done
if ! rustup run stable rustc --version >/dev/null 2>&1; then
  [[ ${BOOTSTRAP_OFFLINE:-0} != 1 ]] || { echo 'Offline Rust stable toolchain missing.' >&2; exit 1; }
  rustup toolchain install stable --profile minimal
fi
rustup default stable
mkdir -p "$HOME/.cargo"
if [[ ! -e "$config" ]]; then
  (set -o noclobber; printf '%s\n' "$expected" >"$config")
fi
rustup run stable rustc --version
rustup run stable cargo --version
mold --version
