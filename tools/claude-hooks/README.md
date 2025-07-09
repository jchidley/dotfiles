# Claude Code Hooks

Python implementation of Claude Code hooks for enforcing development standards from tools/CLAUDE.md.

## Quick Start

### Installation

No installation needed! Uses `uvx` for zero-install execution.

### Configuration

Add to `~/.config/claude/hooks.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "^(Write|Edit|MultiEdit)$",
        "hooks": [
          {
            "type": "command",
            "command": "uvx --from /path/to/claude-hooks claude-hooks"
          }
        ]
      }
    ]
  }
}
```

Once published to PyPI, you can use:
```json
"command": "uvx claude-hooks"
```

## Features

### Automatic Formatting
- **Python**: black, ruff
- **Rust**: cargo fmt  
- **TypeScript/JavaScript**: prettier
- **Pre-commit**: Runs if `.pre-commit-config.yaml` exists

### Validation (Blocking)
- **Bash scripts**: Enforces safety headers (`set -euo pipefail`, `die()` function)
- **Shellcheck**: Validates bash scripts

### Warnings (Non-blocking)
- Missing Bash 4+ version check
- Dangerous arithmetic patterns (`((var++))`)

## Development

```bash
# Clone and setup
cd claude-hooks
uv venv
uv pip install -e .

# Run tests
echo '{"params": {"file_path": "test.py"}}' | uv run claude-hooks

# Debug mode
DEBUG=1 uv run claude-hooks
```

## How It Works

1. Receives JSON via stdin from Claude Code
2. Extracts file path from JSON
3. Runs appropriate formatters (non-blocking)
4. Runs validators (may block on critical errors)
5. Exits with 0 on success, 1 on validation errors