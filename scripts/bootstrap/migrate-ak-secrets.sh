#!/usr/bin/env bash
set -euo pipefail

# Stream an allowlisted AK/GnuPG state set between WSL distributions. This script
# never includes SSH keys, shell history, plaintext secret values, or GnuPG sockets.
mode=${1:-}
execute=${2:-}
state_root="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-secret-migrations"
paths=(
  .gnupg
  .config/ak
  git/ak/secrets
  git/ak/.gpg-key-id
)

fail() { echo "Secret migration error: $*" >&2; exit 1; }
[[ $EUID -ne 0 ]] || fail 'run as the target Linux user, not root'
[[ $(id -u) == "$(stat -c %u "$HOME")" ]] || fail "HOME is not owned by $(id -un)"

validate_tree() {
  local root=$1
  [[ -f "$root/.config/ak/vault.conf" ]] || fail 'AK vault.conf is absent'
  [[ -d "$root/.gnupg/private-keys-v1.d" ]] || fail 'GnuPG private-key directory is absent'
  find "$root/.gnupg/private-keys-v1.d" -type f -name '*.key' -print -quit | grep -q . || fail 'no GnuPG private-key file was found'
  [[ -f "$root/git/ak/.gpg-key-id" ]] || fail 'AK GPG key selection is absent'
  find "$root/git/ak/secrets" -type f -name '*.gpg' -print -quit | grep -q . || fail 'no encrypted AK service file was found'
  if command -v gpg >/dev/null 2>&1; then
    GNUPGHOME="$root/.gnupg" gpg --batch --list-secret-keys >/dev/null 2>&1 || fail 'staged GnuPG keyring is not readable'
  fi
}

case "$mode" in
  export)
    command -v gpgconf >/dev/null 2>&1 && gpgconf --kill gpg-agent >/dev/null 2>&1 || true
    validate_tree "$HOME"
    for path in "${paths[@]}"; do
      [[ ! -e "$HOME/$path" ]] || ! find "$HOME/$path" -type l -print -quit | grep -q . || fail "symlink found in allowlisted path: $path"
    done
    stage=$(mktemp -d)
    trap 'rm -rf "$stage"' EXIT
    for path in "${paths[@]}"; do
      [[ ! -e "$HOME/$path" ]] || while IFS= read -r -d '' file; do
        relative=${file#"$HOME/"}
        mkdir -p "$stage/$(dirname -- "$relative")"
        cp -p "$file" "$stage/$relative"
      done < <(find "$HOME/$path" -type f ! -name '.#lk*' -print0)
    done
    validate_tree "$stage"
    tar -C "$stage" -cf - .
    ;;
  import)
    [[ "$execute" == --execute ]] || fail 'import requires --execute; use Copy-WslAkSecrets.ps1 for preview and transport'
    umask 077
    mkdir -p "$state_root"
    stage=$(mktemp -d "$state_root/stage.XXXXXX")
    archive="$stage/transfer.tar"
    backup="$state_root/backup-$(date -u +%Y%m%dT%H%M%SZ)"
    committed=0
    rollback() {
      local status=$?
      rm -f "$archive"
      if [[ $status -ne 0 && $committed == 1 ]]; then
        echo "Restoring target secret state from $backup" >&2
        for path in "${paths[@]}"; do rm -rf "${HOME:?}/$path"; done
        if [[ -d "$backup/home" ]]; then
          (cd "$backup/home" && cp -a . "$HOME/")
        fi
      fi
      rm -rf "$stage"
      exit "$status"
    }
    trap rollback EXIT
    cat >"$archive"
    while IFS= read -r member; do
      case "$member" in
        .|./|./.gnupg|./.gnupg/|./.gnupg/*|./.config|./.config/|./git|./git/|./git/ak|./git/ak/|./.config/ak|./.config/ak/*|./git/ak/secrets|./git/ak/secrets/*|./git/ak/.gpg-key-id) ;;
        *) fail "archive member is outside the allowlist: $member" ;;
      esac
    done < <(tar -tf "$archive")
    mkdir "$stage/unpacked"
    tar -xf "$archive" -C "$stage/unpacked" --no-same-owner --no-same-permissions
    rm -f "$archive"
    validate_tree "$stage/unpacked"

    mkdir -p "$backup/home"
    chmod 0700 "$backup" "$backup/home"
    for path in "${paths[@]}"; do
      [[ ! -e "$HOME/$path" ]] || (cd "$HOME" && cp -a --parents "$path" "$backup/home")
    done
    committed=1
    for path in "${paths[@]}"; do
      [[ ! -e "$stage/unpacked/$path" ]] || {
        rm -rf "${HOME:?}/$path"
        mkdir -p "$(dirname -- "$HOME/$path")"
        cp -a "$stage/unpacked/$path" "$HOME/$path"
      }
    done
    [[ ${AK_TARGET_DISTRIBUTION:-} =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || fail 'target distribution identity was not supplied by the controller'
    sed -i -E "s/^wsl_distro=.*/wsl_distro=$AK_TARGET_DISTRIBUTION/" "$HOME/.config/ak/vault.conf"
    grep -qx "wsl_distro=$AK_TARGET_DISTRIBUTION" "$HOME/.config/ak/vault.conf" || fail 'target AK route was not rewritten'
    chmod 0700 "$HOME/.gnupg" "$HOME/.config/ak" "$HOME/git/ak/secrets"
    find "$HOME/.gnupg" -type d -exec chmod 0700 {} +
    find "$HOME/.gnupg" -type f -exec chmod 0600 {} +
    find "$HOME/.config/ak" -type f -exec chmod 0600 {} +
    find "$HOME/git/ak/secrets" -type f -exec chmod 0600 {} +
    chmod 0600 "$HOME/git/ak/.gpg-key-id"
    validate_tree "$HOME"
    key_count=$(find "$HOME/.gnupg/private-keys-v1.d" -type f -name '*.key' | wc -l)
    service_count=$(find "$HOME/git/ak/secrets" -type f -name '*.gpg' | wc -l)
    printf '{"schema":1,"completedUtc":"%s","gpgPrivateKeyFiles":%s,"akFiles":%s,"backup":"%s"}\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$key_count" "$service_count" "$backup" >"$state_root/latest-result.json"
    chmod 0600 "$state_root/latest-result.json"
    committed=0
    trap - EXIT
    rm -rf "$stage"
    echo "AK/GnuPG migration completed; prior target state is preserved at $backup"
    ;;
  *) fail 'usage: migrate-ak-secrets.sh export | import --execute' ;;
esac
