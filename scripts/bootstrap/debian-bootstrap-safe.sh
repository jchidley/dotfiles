#!/usr/bin/env bash
set -euo pipefail

# Idempotent Debian/WSL bootstrap driven only by workspace-repos.tsv.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${WORKSPACE_MANIFEST:-$SCRIPT_DIR/workspace-repos.tsv}"
BOOTSTRAP_PROFILE="${BOOTSTRAP_PROFILE:-dev}"
BOOTSTRAP_MODE="${BOOTSTRAP_MODE:-core}"
BOOTSTRAP_GROUPS="${BOOTSTRAP_GROUPS:-}"
BOOTSTRAP_DRY_RUN="${BOOTSTRAP_DRY_RUN:-0}"
SKIP_SYSTEM_PACKAGES="${SKIP_SYSTEM_PACKAGES:-0}"
APPLY_CHEZMOI="${APPLY_CHEZMOI:-0}"

run() {
  if [[ "$BOOTSTRAP_DRY_RUN" == 1 ]]; then
    printf 'DRY-RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

install_fnm() {
  local fnm_dir fnm_bin asset tmp_dir default_version
  fnm_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fnm"
  fnm_bin="$fnm_dir/fnm"

  if [[ ! -x "$fnm_bin" ]]; then
    case "$(uname -m)" in
      x86_64|amd64) asset=fnm-linux.zip ;;
      aarch64|arm64) asset=fnm-arm64.zip ;;
      armv7l|armv6l) asset=fnm-arm32.zip ;;
      *) echo "Unsupported architecture for fnm: $(uname -m)" >&2; return 1 ;;
    esac

    if [[ "$BOOTSTRAP_DRY_RUN" == 1 ]]; then
      echo "DRY-RUN: install latest fnm release ($asset) at $fnm_bin"
      echo "DRY-RUN: install and select the latest Node.js LTS if no default exists"
      return 0
    fi

    (
      tmp_dir=$(mktemp -d)
      trap 'rm -rf "$tmp_dir"' EXIT
      curl -fL --retry 3 --connect-timeout 10 --max-time 120 \
        "https://github.com/Schniz/fnm/releases/latest/download/$asset" \
        -o "$tmp_dir/fnm.zip"
      unzip -q "$tmp_dir/fnm.zip" -d "$tmp_dir/unpacked"
      install -d -m 755 "$fnm_dir"
      install -m 755 "$tmp_dir/unpacked/fnm" "$fnm_bin"
    )
  else
    echo "  - fnm already installed: $($fnm_bin --version)"
  fi

  [[ "$BOOTSTRAP_DRY_RUN" == 1 ]] && return 0
  export PATH="$fnm_dir:$PATH"
  eval "$("$fnm_bin" env --shell bash)"
  default_version=$(fnm default 2>/dev/null || true)
  if [[ -z "$default_version" ]]; then
    fnm install --lts --use --progress never
    fnm default "$(fnm current)"
  else
    fnm use "$default_version"
  fi
}

case "${BOOTSTRAP_MODE,,}" in
  core) default_groups="foundation" ;;
  full) default_groups="foundation,active,references,optional" ;;
  *) echo "Invalid BOOTSTRAP_MODE: $BOOTSTRAP_MODE (expected core or full)" >&2; exit 2 ;;
esac
BOOTSTRAP_GROUPS="${BOOTSTRAP_GROUPS:-$default_groups}"

[[ -r "$MANIFEST" ]] || { echo "Manifest not readable: $MANIFEST" >&2; exit 2; }

group_selected() {
  [[ ",${BOOTSTRAP_GROUPS}," == *",$1,"* ]]
}

profile_selected() {
  [[ "$1" == all || ",$1," == *",${BOOTSTRAP_PROFILE},"* ]]
}

expand_destination() {
  case "$1" in
    \~) printf '%s\n' "$HOME" ;;
    \~/*) printf '%s/%s\n' "$HOME" "${1:2}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

if [[ "$SKIP_SYSTEM_PACKAGES" != 1 ]]; then
  run sudo apt update
  run sudo apt install -y ca-certificates curl direnv dirmngr git gnupg2 jq openssh-client pinentry-curses shellcheck sqlite3 tmux unzip zoxide
fi

run mkdir -p "$HOME/github" "$HOME/tools" "$HOME/work" "$HOME/.local/bin"
install_fnm

echo "==> Repository manifest: profile=$BOOTSTRAP_PROFILE groups=$BOOTSTRAP_GROUPS"
while IFS=$'\t' read -r group kind repository destination profiles extra; do
  [[ -z "${group:-}" || "$group" == \#* ]] && continue
  [[ -z "${extra:-}" ]] || { echo "Invalid manifest row for $repository" >&2; exit 2; }
  group_selected "$group" || continue
  profile_selected "$profiles" || continue
  destination="$(expand_destination "$destination")"

  case "$kind" in
    chezmoi)
      if [[ -d "$destination/.git" ]]; then
        echo "  - $repository already initialised at $destination"
      else
        run chezmoi init "$repository"
      fi
      ;;
    git)
      if [[ -d "$destination/.git" ]]; then
        echo "  - $repository already exists at $destination"
      elif [[ -e "$destination" ]]; then
        echo "Refusing to replace non-Git destination: $destination" >&2
        exit 1
      else
        run mkdir -p "$(dirname -- "$destination")"
        run git clone "git@github.com:${repository}.git" "$destination"
      fi
      ;;
    *) echo "Unknown manifest kind '$kind' for $repository" >&2; exit 2 ;;
  esac
done < "$MANIFEST"

AK_REPO="$HOME/github/ak"
if [[ -x "$AK_REPO/bin/ak" ]]; then
  run ln -sfn "$AK_REPO/bin/ak" "$HOME/.local/bin/ak"
  [[ ! -x "$AK_REPO/bin/ak-ssh-askpass" ]] || run ln -sfn "$AK_REPO/bin/ak-ssh-askpass" "$HOME/.local/bin/ak-ssh-askpass"
  run mkdir -p "$HOME/.config/direnv/lib"
  run ln -sfn "$AK_REPO/integrations/direnv.sh" "$HOME/.config/direnv/lib/ak.sh"
fi

if [[ -x "$HOME/github/agent-skills/install.sh" ]]; then
  run "$HOME/github/agent-skills/install.sh" install pi
fi

if [[ "$APPLY_CHEZMOI" == 1 ]]; then
  run chezmoi apply
else
  echo "  - chezmoi apply deferred; inspect with: chezmoi diff"
fi

echo "Bootstrap complete. 'full' means every explicitly declared manifest group, never every GitHub repository."
