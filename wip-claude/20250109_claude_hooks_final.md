# Claude Code Hooks - Final Implementation

## Overview

Python implementation of Claude Code hooks that enforces mechanical patterns from `tools/CLAUDE.md` automatically when code is modified. Located at `tools/claude-hooks/` and deployed to `~/tools/claude-hooks/`.

## Key Insights from Development

### 1. Codebase as Implicit Style Guide
**From user**: Claude learns from existing patterns in the codebase. If hooks maintain perfect consistency, the codebase itself becomes the teacher, making explicit formatting instructions less necessary.

**Implication**: Aggressive automation of mechanical patterns actually *enhances* Claude's learning by providing consistent examples.

### 2. Python-First Simplification
Started with hybrid bash/Python approach, but realized Python can handle both simple and complex tasks via subprocess. One language = simpler maintenance.

## Current Implementation

### Structure
```
tools/claude-hooks/
├── pyproject.toml         # Package config (requires-python = ">=3.12")
├── src/claude_hooks/
│   ├── main.py           # Entry point, JSON handling
│   ├── formatters.py     # Language-specific formatting
│   └── validators.py     # Validation checks (bash headers, etc.)
├── hooks.json            # Claude Code configuration
├── test-hooks.sh         # Test suite
└── README.md            # Documentation
```

### Features Implemented

#### Automatic Formatting (Non-blocking)
- **Python**: black, ruff --fix
- **Rust**: cargo fmt (in Rust projects)
- **TypeScript/JS**: prettier
- **Pre-commit**: Runs if .pre-commit-config.yaml exists

#### Validation (Blocking)
- **Bash scripts**: 
  - Must have `set -euo pipefail`
  - Must have `die()` function
  - Warns on dangerous patterns like `((var++))`
  - Runs shellcheck if available

### Installation
```bash
cd ~/.local/share/chezmoi
./tools/install-python-hooks.sh
```

This installs `~/.config/claude/hooks.json`:
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "^(Write|Edit|MultiEdit)$",
      "hooks": [{
        "type": "command",
        "command": "uvx --from ~/tools/claude-hooks claude-hooks"
      }]
    }]
  }
}
```

## Future Expansion Possibilities

Based on analysis of `tools/CLAUDE.md`, these patterns could be added:

### Phase 1: High-Value, Low-Complexity
1. **ABOUTME comment checker** - Ensure documentation in files > 10 lines
2. **Test file reminder** - Suggest creating tests for new implementation files
3. **Console output detector** - Warn about print statements in test files
4. **README structure validator** - Check for usage section near top

### Phase 2: Medium-Complexity  
1. **Test effectiveness validator** - AST analysis to detect structure-only assertions
2. **Magic number detector** - Flag unexplained numeric constants
3. **Import/dependency validator** - Check imports against package files

### Phase 3: Advanced (Requires Sophistication)
1. **Documentation freshness** - Detect stale comments via AST
2. **Refactoring safety** - Analyze if changes mix refactoring with behavior
3. **Cross-file validation** - Ensure consistent patterns across related files

## What Stays in CLAUDE.md vs Hooks

### Hooks Handle (Mechanical)
- Formatting commands
- Linting fixes
- Header requirements
- Simple pattern detection

### CLAUDE.md Handles (Philosophical)
- Language selection logic ("Can it be done with bash?")
- Development modes (Planning, Implementation, Refactoring)
- Empirical development principles
- Thinking triggers
- Anti-patterns requiring judgment

## Benefits of This Approach

1. **Zero-install execution** - uvx handles everything
2. **Cross-platform** - Python works everywhere
3. **Extensible** - Easy to add new validators
4. **Consistent codebase** - Mechanical patterns always enforced
5. **Clear separation** - Philosophy in docs, mechanics in code

## Next Steps

1. Use the hooks and observe their effectiveness
2. Consider publishing to PyPI for easier distribution: `uvx claude-hooks`
3. Add high-value validators from Phase 1
4. Gather feedback on which patterns cause most friction