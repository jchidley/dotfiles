#!/usr/bin/env bash
set -euo pipefail

# Rebuild the declared Debian/WSL workspace without relying on pre-existing tools,
# credentials, shell state, or root-owned files in the user's home directory.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${WORKSPACE_MANIFEST:-$SCRIPT_DIR/workspace-repos.tsv}"
VERSION_LOCK="${BOOTSTRAP_VERSION_LOCK:-$SCRIPT_DIR/bootstrap-versions.env}"
BOOTSTRAP_PROFILE="${BOOTSTRAP_PROFILE:-dev}"
BOOTSTRAP_MODE="${BOOTSTRAP_MODE:-core}"
BOOTSTRAP_GROUPS="${BOOTSTRAP_GROUPS:-}"
BOOTSTRAP_DRY_RUN="${BOOTSTRAP_DRY_RUN:-0}"
BOOTSTRAP_OFFLINE="${BOOTSTRAP_OFFLINE:-0}"
BOOTSTRAP_CACHE="${BOOTSTRAP_CACHE:-$HOME/.cache/dotfiles-bootstrap}"
SKIP_SYSTEM_PACKAGES="${SKIP_SYSTEM_PACKAGES:-0}"
APPLY_CHEZMOI="${APPLY_CHEZMOI:-0}"
DOTFILES_APPLY_WSL_INTEGRATION="${DOTFILES_APPLY_WSL_INTEGRATION:-0}"
BOOTSTRAP_STATE_DIR="${BOOTSTRAP_STATE_DIR:-$HOME/.local/state/dotfiles-bootstrap}"

run() {
  if [[ "$BOOTSTRAP_DRY_RUN" == 1 ]]; then
    printf 'DRY-RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

fail() { echo "Bootstrap error: $*" >&2; exit 1; }
marker() { printf 'bootstrap-check:%s:%s\n' "$1" "$2"; }

[[ -r "$MANIFEST" ]] || fail "manifest not readable: $MANIFEST"
[[ -r "$VERSION_LOCK" ]] || fail "version lock not readable: $VERSION_LOCK"
# The caller may override this repository-owned lock path.
# shellcheck disable=SC1090
source "$VERSION_LOCK"
[[ "${BOOTSTRAP_LOCK_SCHEMA:-}" == 1 ]] || fail "unsupported version-lock schema"
[[ $BOOTSTRAP_DRY_RUN =~ ^[01]$ && $BOOTSTRAP_OFFLINE =~ ^[01]$ ]] || fail "boolean options must be 0 or 1"
[[ $APPLY_CHEZMOI =~ ^[01]$ && $DOTFILES_APPLY_WSL_INTEGRATION =~ ^[01]$ ]] || fail "boolean options must be 0 or 1"
[[ $EUID -ne 0 ]] || fail "run as the target user, not root; sudo is used only for system provisioning"
[[ $(id -u) == "$(stat -c %u "$HOME")" ]] || fail "HOME is not owned by the target user: $HOME"
case "$(uname -m)" in x86_64|amd64) ;; *) fail "the current lock supports only x86-64" ;; esac

if [[ "$BOOTSTRAP_DRY_RUN" != 1 ]]; then
  expected_runtime="/run/user/$(id -u)"
  if [[ ! -d "$expected_runtime" ]]; then
    sudo install -d -o "$(id -u)" -g "$(id -g)" -m 0700 "$expected_runtime"
  fi
  [[ -O "$expected_runtime" && -w "$expected_runtime" ]] || fail "runtime directory is not owned and writable by the target user: $expected_runtime"
  export XDG_RUNTIME_DIR="$expected_runtime"
fi

fetch_locked() {
  local name=$1 file=$2 url=$3 expected=$4 temporary
  local destination="$BOOTSTRAP_CACHE/$file"
  if [[ -f "$destination" ]] && printf '%s  %s\n' "$expected" "$destination" | sha256sum -c - >/dev/null 2>&1; then
    marker "$name-cache" hit >&2
    printf '%s\n' "$destination"
    return 0
  fi
  [[ "$BOOTSTRAP_OFFLINE" != 1 ]] || fail "offline cache miss or hash mismatch: $destination"
  if [[ "$BOOTSTRAP_DRY_RUN" == 1 ]]; then
    echo "DRY-RUN: download $url -> $destination" >&2
    printf '%s\n' "$destination"
    return 0
  fi
  mkdir -p "$BOOTSTRAP_CACHE"
  temporary=$(mktemp "$BOOTSTRAP_CACHE/.${file}.XXXXXX")
  trap 'rm -f "${temporary:-}"' RETURN
  curl -fL --retry 3 --connect-timeout 10 --max-time 300 "$url" -o "$temporary"
  printf '%s  %s\n' "$expected" "$temporary" | sha256sum -c - >/dev/null
  chmod 0644 "$temporary"
  mv -f "$temporary" "$destination"
  trap - RETURN
  marker "$name-cache" downloaded >&2
  printf '%s\n' "$destination"
}

install_chezmoi() {
  local archive tmp binary="$HOME/.local/bin/chezmoi"
  archive=$(fetch_locked chezmoi "$CHEZMOI_FILE" "$CHEZMOI_URL" "$CHEZMOI_SHA256")
  if [[ "$BOOTSTRAP_DRY_RUN" == 1 ]]; then echo "DRY-RUN: install chezmoi $CHEZMOI_VERSION at $binary"; return; fi
  if [[ -x "$binary" && $($binary --version) == "chezmoi version v$CHEZMOI_VERSION,"* ]]; then marker chezmoi "$CHEZMOI_VERSION"; return; fi
  tmp=$(mktemp -d); trap 'rm -rf "${tmp:-}"' RETURN
  tar -xzf "$archive" -C "$tmp"
  install -m 0755 "$tmp/chezmoi" "$binary"
  trap - RETURN; rm -rf "$tmp"
  [[ $($binary --version) == "chezmoi version v$CHEZMOI_VERSION,"* ]] || fail "chezmoi version verification failed"
  marker chezmoi "$CHEZMOI_VERSION"
}

install_fnm_and_node() {
  local fnm_archive node_archive tmp fnm_dir="$HOME/.local/share/fnm" fnm_bin node_dir
  fnm_bin="$fnm_dir/fnm"
  node_dir="$fnm_dir/node-versions/v$NODE_VERSION/installation"
  fnm_archive=$(fetch_locked fnm "$FNM_FILE" "$FNM_URL" "$FNM_SHA256")
  node_archive=$(fetch_locked node "$NODE_FILE" "$NODE_URL" "$NODE_SHA256")
  if [[ "$BOOTSTRAP_DRY_RUN" == 1 ]]; then echo "DRY-RUN: install fnm $FNM_VERSION and Node v$NODE_VERSION"; return; fi
  mkdir -p "$fnm_dir"
  if [[ ! -x "$fnm_bin" || $($fnm_bin --version) != "fnm $FNM_VERSION" ]]; then
    tmp=$(mktemp -d); trap 'rm -rf "${tmp:-}"' RETURN
    unzip -q "$fnm_archive" -d "$tmp"
    install -m 0755 "$tmp/fnm" "$fnm_bin"
    trap - RETURN; rm -rf "$tmp"
  fi
  if [[ ! -x "$node_dir/bin/node" || $("$node_dir/bin/node" --version) != "v$NODE_VERSION" ]]; then
    rm -rf "$node_dir"
    mkdir -p "$node_dir"
    tar -xJf "$node_archive" --strip-components=1 -C "$node_dir"
  fi
  export PATH="$fnm_dir:$PATH"
  eval "$("$fnm_bin" env --shell bash)"
  "$fnm_bin" default "v$NODE_VERSION" >/dev/null
  "$fnm_bin" use "v$NODE_VERSION" >/dev/null
  [[ $(fnm --version) == "fnm $FNM_VERSION" ]] || fail "fnm version verification failed"
  [[ $(node --version) == "v$NODE_VERSION" ]] || fail "Node version verification failed"
  marker fnm "$FNM_VERSION"
  marker node "$NODE_VERSION"
}

install_mcfly() {
  local archive tmp binary="$HOME/.local/bin/mcfly"
  archive=$(fetch_locked mcfly "$MCFLY_FILE" "$MCFLY_URL" "$MCFLY_SHA256")
  if [[ "$BOOTSTRAP_DRY_RUN" == 1 ]]; then echo "DRY-RUN: install McFly $MCFLY_VERSION at $binary"; return; fi
  if [[ ! -x "$binary" || $($binary --version) != "mcfly $MCFLY_VERSION" ]]; then
    tmp=$(mktemp -d); trap 'rm -rf "${tmp:-}"' RETURN
    tar -xzf "$archive" -C "$tmp"
    install -m 0755 "$tmp/mcfly" "$binary"
    trap - RETURN; rm -rf "$tmp"
  fi
  [[ $($binary --version) == "mcfly $MCFLY_VERSION" ]] || fail "McFly version verification failed"
  marker mcfly "$MCFLY_VERSION"
}

install_pi() {
  local archive package='@earendil-works/pi-coding-agent'
  archive=$(fetch_locked pi "$PI_FILE" "$PI_URL" "$PI_SHA256")
  if [[ "$BOOTSTRAP_DRY_RUN" == 1 ]]; then echo "DRY-RUN: install Pi $PI_VERSION from $archive"; return; fi
  case "$(command -v node 2>/dev/null || true)" in /mnt/c/*|"") fail "native fnm-managed Node.js is unavailable" ;; esac
  if ! command -v pi >/dev/null 2>&1 || [[ $(pi --version) != "$PI_VERSION" ]]; then
    npm install -g "$archive"
  fi
  [[ $(pi --version) == "$PI_VERSION" ]] || fail "Pi version verification failed"
  npm list -g --depth=0 "$package" >/dev/null
  marker npm "$(npm --version)"
  marker pi "$PI_VERSION"
}

case "${BOOTSTRAP_MODE,,}" in
  core) default_groups=foundation ;;
  full) default_groups=foundation,active,references,optional ;;
  *) fail "invalid BOOTSTRAP_MODE: $BOOTSTRAP_MODE (expected core or full)" ;;
esac
BOOTSTRAP_GROUPS="${BOOTSTRAP_GROUPS:-$default_groups}"
group_selected() { [[ ",${BOOTSTRAP_GROUPS}," == *",$1,"* ]]; }
profile_selected() { [[ "$1" == all || ",$1," == *",${BOOTSTRAP_PROFILE},"* ]]; }
expand_destination() { case "$1" in \~) printf '%s\n' "$HOME" ;; \~/*) printf '%s/%s\n' "$HOME" "${1:2}" ;; *) printf '%s\n' "$1" ;; esac; }

if [[ "$SKIP_SYSTEM_PACKAGES" != 1 ]]; then
  run sudo apt-get update
  run sudo apt-get install -y ca-certificates curl direnv dirmngr git gnupg2 jq openssh-client pinentry-curses restic shellcheck sqlite3 sudo tmux unzip xz-utils zoxide
fi
run mkdir -p "$HOME/git" "$HOME/work" "$HOME/.local/bin" "$BOOTSTRAP_STATE_DIR"
install_chezmoi
install_fnm_and_node
install_mcfly
install_pi

RESTIC_HOME_INSTALLER="$SCRIPT_DIR/../wsl-backup/home/install.sh"
[[ ! -x "$RESTIC_HOME_INSTALLER" ]] || run "$RESTIC_HOME_INSTALLER"
WSL_SYSTEM_BACKUP_INSTALLER="$SCRIPT_DIR/../wsl-backup/system/install.sh"
[[ ! -x "$WSL_SYSTEM_BACKUP_INSTALLER" ]] || run "$WSL_SYSTEM_BACKUP_INSTALLER"

echo "==> Repository manifest: profile=$BOOTSTRAP_PROFILE groups=$BOOTSTRAP_GROUPS"
while IFS=$'\t' read -r group _kind repository destination profiles extra; do
  [[ -z "${group:-}" || "$group" == \#* ]] && continue
  [[ -z "${extra:-}" ]] || fail "invalid manifest row for $repository"
  group_selected "$group" || continue
  profile_selected "$profiles" || continue
  destination="$(expand_destination "$destination")"
  case "$_kind" in chezmoi|git) ;; *) fail "unknown manifest kind: $_kind" ;; esac
  if [[ -d "$destination/.git" ]]; then
    echo "  - $repository already exists at $destination"
  elif [[ -e "$destination" ]]; then
    fail "refusing to replace non-Git destination: $destination"
  else
    run mkdir -p "$(dirname -- "$destination")"
    run git clone "https://github.com/${repository}.git" "$destination"
  fi
  [[ "$BOOTSTRAP_DRY_RUN" == 1 ]] || marker "repository-$repository" "$(git -C "$destination" rev-parse HEAD)"
done < "$MANIFEST"

AK_REPO="$HOME/git/ak"
if [[ -x "$AK_REPO/bin/ak" ]]; then
  run ln -sfn "$AK_REPO/bin/ak" "$HOME/.local/bin/ak"
  [[ ! -x "$AK_REPO/bin/ak-ssh-askpass" ]] || run ln -sfn "$AK_REPO/bin/ak-ssh-askpass" "$HOME/.local/bin/ak-ssh-askpass"
  run mkdir -p "$HOME/.config/direnv/lib"
  run ln -sfn "$AK_REPO/integrations/direnv.sh" "$HOME/.config/direnv/lib/ak.sh"
fi
if [[ -x "$HOME/git/agent-skills/install.sh" ]]; then
  run "$HOME/git/agent-skills/install.sh" install pi
  if [[ "$BOOTSTRAP_DRY_RUN" != 1 ]]; then
    pi list | grep -F "$HOME/git/agent-skills" >/dev/null || fail "Pi agent-skills package registration is absent"
    marker pi-package "$HOME/git/agent-skills"
  fi
fi

if [[ "$APPLY_CHEZMOI" == 1 ]]; then
  export DOTFILES_APPLY_WSL_INTEGRATION
  run "$HOME/.local/bin/chezmoi" apply
else
  echo "  - chezmoi apply deferred; inspect with: chezmoi diff"
fi

if [[ "$BOOTSTRAP_DRY_RUN" != 1 ]]; then
  repositories=$(while IFS=$'\t' read -r group _ repository destination profiles extra; do
    [[ -z "${group:-}" || "$group" == \#* || -n "${extra:-}" ]] && continue
    if ! group_selected "$group" || ! profile_selected "$profiles"; then continue; fi
    destination="$(expand_destination "$destination")"
    jq -nc --arg repository "$repository" --arg path "$destination" --arg commit "$(git -C "$destination" rev-parse HEAD)" '{repository:$repository,path:$path,commit:$commit}'
  done < "$MANIFEST" | jq -s .)
  jq -n \
    --arg createdUtc "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg profile "$BOOTSTRAP_PROFILE" --arg groups "$BOOTSTRAP_GROUPS" \
    --arg chezmoi "$("$HOME/.local/bin/chezmoi" --version)" --arg fnm "$(fnm --version)" \
    --arg node "$(node --version)" --arg npm "$(npm --version)" --arg pi "$(pi --version)" \
    --arg mcfly "$("$HOME/.local/bin/mcfly" --version)" --argjson repositories "$repositories" \
    '{schema:1,createdUtc:$createdUtc,profile:$profile,groups:$groups,chezmoi:$chezmoi,fnm:$fnm,node:$node,npm:$npm,pi:$pi,mcfly:$mcfly,repositories:$repositories,secrets:"not-copied"}' \
    >"$BOOTSTRAP_STATE_DIR/installed-manifest.json"
  chmod 0600 "$BOOTSTRAP_STATE_DIR/installed-manifest.json"
  marker manifest "$BOOTSTRAP_STATE_DIR/installed-manifest.json"
fi

echo "Bootstrap complete. Secrets and host-wide WSL integration are separate explicit operations."
