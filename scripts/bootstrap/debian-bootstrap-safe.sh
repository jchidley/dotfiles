#!/usr/bin/env bash
set -euo pipefail

# Safer / idempotent Debian bootstrap.

GITHUB_USER="${GITHUB_USER:-jchidley}"
WORKDIR="${HOME}/github"
BOOTSTRAP_MODE="${BOOTSTRAP_MODE:-}" # core|full
# Comma-separated list used when BOOTSTRAP_MODE=core.
WHITELIST_REPOS="${WHITELIST_REPOS:-dotfiles,ak,agent-skills,tools}"
# Comma-separated list used when BOOTSTRAP_MODE=full.
EXCLUDE_REPOS="${EXCLUDE_REPOS:-core,chibicc-riscv,alpine_images,PythonCookbook,beads,test-repo-skill3-delete,tools,ardupilot,plover,Picocomputer,ThinkDSP,open-fpga-verilog-tutorial,claude-code-log,generative-factory-c-compiler,helix-ai,fsharpExperiments,SAP,PiPcd8544Demo,SerialMessages,GSIOT-NP2,nmigen_learning}"

echo "==> Updating system"
sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl unzip jq sqlite3 openssh-client ca-certificates gnupg2 dirmngr pinentry-curses direnv zoxide hx tmux bat

echo "==> Configuring gpg-agent cache TTL (20h)"
mkdir -p "${HOME}/.gnupg"
chmod 700 "${HOME}/.gnupg"
cat > "${HOME}/.gnupg/gpg-agent.conf" <<'EOF'
default-cache-ttl 72000
max-cache-ttl 72000
pinentry-program /usr/bin/pinentry-curses
EOF
chmod 600 "${HOME}/.gnupg/gpg-agent.conf"
gpgconf --kill gpg-agent || true
gpgconf --launch gpg-agent || true

echo "==> Ensuring SSH key exists"
if [[ ! -f "${HOME}/.ssh/id_ed25519" ]]; then
  ssh-keygen -t ed25519 -C "${GITHUB_USER}" -f "${HOME}/.ssh/id_ed25519" -N ""
fi

# Start agent and load key
eval "$(ssh-agent -s)"
ssh-add "${HOME}/.ssh/id_ed25519" >/dev/null 2>&1 || true

echo "==> Testing existing GitHub SSH auth"
ssh_test_output="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)"
if grep -qi "successfully authenticated" <<<"${ssh_test_output}"; then
  echo "  - Existing SSH key already works with GitHub"
  echo "${ssh_test_output}"
else
  echo
  echo "=== Add this public key to GitHub → Settings → SSH keys ==="
  cat "${HOME}/.ssh/id_ed25519.pub"
  echo "==========================================================="
  read -rp "Press Enter once key is added to GitHub..."

  echo "==> Testing GitHub SSH auth"
  ssh -o StrictHostKeyChecking=accept-new -T git@github.com || true
fi

echo "==> Reading GitHub token (for API only)"
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  if command -v ak >/dev/null 2>&1; then
    GITHUB_TOKEN="$(ak get github 2>/dev/null || true)"
    if [[ -n "${GITHUB_TOKEN}" ]]; then
      echo "  - Using token from ak"
    fi
  elif [[ -x "${HOME}/tools/api-keys/bin/ak" ]]; then
    GITHUB_TOKEN="$("${HOME}/tools/api-keys/bin/ak" get github 2>/dev/null || true)"
    if [[ -n "${GITHUB_TOKEN}" ]]; then
      echo "  - Using token from ~/tools/api-keys/bin/ak"
    fi
  fi
fi

if [[ -z "${GITHUB_TOKEN:-}" ]] && command -v gh >/dev/null 2>&1; then
  GITHUB_TOKEN="$(gh auth token 2>/dev/null || true)"
  if [[ -n "${GITHUB_TOKEN}" ]]; then
    echo "  - Using token from gh auth"
  fi
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  read -rsp "Enter GitHub token (repo read access): " GITHUB_TOKEN
  echo
fi

if ! curl -fsSL \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/user" >/dev/null; then
  echo "GitHub token is invalid or missing required scopes (need repo read access)." >&2
  exit 1
fi

mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

if [[ -z "${BOOTSTRAP_MODE}" ]]; then
  if [[ -t 0 ]]; then
    read -rp "Select bootstrap mode [core/full] (default: core): " BOOTSTRAP_MODE
    BOOTSTRAP_MODE="${BOOTSTRAP_MODE:-core}"
  else
    BOOTSTRAP_MODE="core"
  fi
fi

BOOTSTRAP_MODE="$(echo "${BOOTSTRAP_MODE}" | tr '[:upper:]' '[:lower:]')"

if [[ "${BOOTSTRAP_MODE}" != "core" && "${BOOTSTRAP_MODE}" != "full" ]]; then
  echo "Invalid BOOTSTRAP_MODE: ${BOOTSTRAP_MODE} (expected: core|full)" >&2
  exit 1
fi

echo "==> Cloning repos for ${GITHUB_USER} (mode: ${BOOTSTRAP_MODE})"
page=1
while :; do
  repos_json="$(curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/user/repos?per_page=100&page=${page}")"

  count="$(jq 'length' <<<"${repos_json}")"
  [[ "${count}" -eq 0 ]] && break

  jq -r '.[].ssh_url' <<<"${repos_json}" | while read -r repo_url; do
    repo_name="$(basename "${repo_url}" .git)"

    if [[ "${BOOTSTRAP_MODE}" == "core" ]]; then
      if [[ ",${WHITELIST_REPOS}," != *",${repo_name},"* ]]; then
        echo "  - ${repo_name} (not in core whitelist, skipping)"
        continue
      fi
    else
      if [[ ",${EXCLUDE_REPOS}," == *",${repo_name},"* ]]; then
        echo "  - ${repo_name} (excluded, skipping)"
        continue
      fi
    fi

    if [[ -d "${repo_name}/.git" ]]; then
      echo "  - ${repo_name} (already exists, skipping)"
    else
      echo "  - cloning ${repo_name}"
      git clone "${repo_url}"
    fi
  done

  ((page++))
done

echo "==> Placing tools repo at ~/tools (if applicable)"
if [[ -d "${WORKDIR}/tools" ]]; then
  if [[ ! -e "${HOME}/tools" ]]; then
    mv "${WORKDIR}/tools" "${HOME}/tools"
  else
    echo "  - ${HOME}/tools already exists; leaving ${WORKDIR}/tools in place"
  fi
fi

echo "==> Syncing ak scripts into ~/tools/api-keys"
if [[ -d "${WORKDIR}/ak" ]]; then
  mkdir -p "${HOME}/tools/api-keys"
  # Keep runtime copy non-git: remove copied repo metadata if present, then sync files excluding .git
  rm -rf "${HOME}/tools/api-keys/.git"
  (cd "${WORKDIR}/ak" && tar --exclude=.git -cf - .) | (cd "${HOME}/tools/api-keys" && tar -xpf -)

  mkdir -p "${HOME}/.config/direnv/lib"
  ln -sf "${HOME}/tools/api-keys/integrations/direnv.sh" "${HOME}/.config/direnv/lib/ak.sh"

  echo "==> Creating ~/.envrc with minimum keys"
  cat > "${HOME}/.envrc" <<'EOF'
use_ak github brave groq openrouter deepinfra
EOF

  echo "==> Allowing direnv in ~"
  direnv allow "${HOME}" || true
else
  echo "  - ${WORKDIR}/ak not found; skipping ak sync/.envrc setup"
fi

echo "==> Installing agent-skills for pi"
if [[ -x "${WORKDIR}/agent-skills/install.sh" ]]; then
  "${WORKDIR}/agent-skills/install.sh" install pi
else
  echo "  - ${WORKDIR}/agent-skills/install.sh not found; skipping"
fi

echo "==> Installing chezmoi"
sh -c "$(curl -fsLS get.chezmoi.io)"

CHEZMOI_BIN="$(command -v chezmoi || true)"
if [[ -z "${CHEZMOI_BIN}" && -x "${HOME}/.local/bin/chezmoi" ]]; then
  CHEZMOI_BIN="${HOME}/.local/bin/chezmoi"
fi

if [[ -n "${CHEZMOI_BIN}" ]]; then
  APPLY_CHEZMOI="${APPLY_CHEZMOI:-}"
  if [[ -z "${APPLY_CHEZMOI}" && -t 0 ]]; then
    read -rp "Apply chezmoi dotfiles now? [y/N]: " APPLY_CHEZMOI
  fi

  if [[ "${APPLY_CHEZMOI,,}" =~ ^(y|yes)$ ]]; then
    "${CHEZMOI_BIN}" init --apply "${GITHUB_USER}"
  else
    echo "  - Skipping chezmoi apply (run later with: chezmoi init --apply ${GITHUB_USER})"
  fi
else
  echo "  - chezmoi binary not found after install; skipping apply"
fi

echo "==> Installing mcfly (if needed)"
if ! command -v mcfly >/dev/null 2>&1; then
  if [[ -f "${WORKDIR}/mcfly/ci/install.sh" ]]; then
    sh "${WORKDIR}/mcfly/ci/install.sh" --git cantino/mcfly --to "${HOME}/.local/bin"
  else
    curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sh -s -- --git cantino/mcfly --to "${HOME}/.local/bin"
  fi
fi

echo "==> Installing fnm (if needed)"
if ! command -v fnm >/dev/null 2>&1; then
  curl -fsSL https://fnm.vercel.app/install | bash
fi

# Load fnm for this shell (without relying on interactive .bashrc)
export PATH="${HOME}/.local/share/fnm:${PATH}"
eval "$(fnm env --use-on-cd)"

echo "==> Installing Node LTS"
fnm install --lts
fnm default lts-latest
fnm use lts-latest

echo "==> Installing global npm package(s)"
npm install -g @mariozechner/pi-coding-agent

echo "==> Installing Bitwarden CLI (optional, for McFly password retrieval)"
if ! command -v bw >/dev/null 2>&1; then
  npm install -g @bitwarden/cli || echo "  - Failed to install @bitwarden/cli; McFly scripts will prompt for password"
fi

if [[ -x "${HOME}/tools/api-keys/bin/ak" ]]; then
  AK_INIT_NOW="${AK_INIT_NOW:-}"
  if [[ -z "${AK_INIT_NOW}" && -t 0 ]]; then
    read -rp "Run 'ak init' now? [y/N]: " AK_INIT_NOW
  fi

  if [[ "${AK_INIT_NOW,,}" =~ ^(y|yes)$ ]]; then
    "${HOME}/tools/api-keys/bin/ak" init || echo "  - ak init did not complete; run later with: ak init"
  else
    echo "  - Skipping ak init (run later with: ak init)"
  fi
fi

echo "✅ Bootstrap complete."
