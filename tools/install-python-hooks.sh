#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
DEBUG="${DEBUG:-0}"

die() { echo "ERROR: $*" >&2; exit 1; }
[[ "${BASH_VERSION%%.*}" -ge 4 ]] || die "Bash 4+ required"

# ABOUTME: Install Claude Code hooks (Python implementation)
# Copies the hooks.json configuration to the Claude config directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_CONFIG="${SCRIPT_DIR}/claude-hooks/hooks.json"
CONFIG_DIR="${HOME}/.config/claude"

echo "Installing Claude Code hooks (Python implementation)..."

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Validate source file exists
[[ -f "$HOOKS_CONFIG" ]] || die "Hooks config not found: $HOOKS_CONFIG"

# Backup existing hooks.json if present
if [[ -f "$CONFIG_DIR/hooks.json" ]]; then
    backup_file="$CONFIG_DIR/hooks.json.bak.$(date +%Y%m%d_%H%M%S)"
    echo "Backing up existing hooks.json to $backup_file"
    cp "$CONFIG_DIR/hooks.json" "$backup_file"
fi

# Install hooks configuration
echo "Installing hooks configuration to $CONFIG_DIR/hooks.json"
cp "$HOOKS_CONFIG" "$CONFIG_DIR/hooks.json"

echo ""
echo "✓ Claude Code hooks (Python) installed successfully!"
echo ""
echo "The hooks will automatically enforce:"
echo "  • Python: black formatting, ruff linting"
echo "  • Rust: cargo fmt (in Rust projects)"
echo "  • TypeScript/JS: prettier formatting"
echo "  • Bash: shellcheck validation, required safety headers"
echo "  • Pre-commit: runs if .pre-commit-config.yaml exists"
echo ""
echo "The Python implementation provides:"
echo "  • Cross-platform compatibility"
echo "  • Better error handling"
echo "  • Extensible architecture for future validators"
echo ""
echo "IMPORTANT: After running 'chezmoi apply', the claude-hooks will be at:"
echo "  ~/tools/claude-hooks/"
echo ""
echo "The hooks.json references this location for execution."
echo ""
echo "To test: DEBUG=1 to see hook processing details"
echo "To uninstall: rm $CONFIG_DIR/hooks.json"