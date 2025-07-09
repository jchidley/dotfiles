# Claude Hooks: Comprehensive Implementation Plan
Created: 2025-01-09 18:30
Updated: 2025-01-09 18:55 (revised with separation of concerns)

## Configuration Hierarchy

1. **dot_claude/CLAUDE.md** - Global invariants (ALWAYS active)
2. **claude-hooks** - Mechanical enforcement (ALWAYS active)
3. **tools/CLAUDE.md** - Philosophy & complex patterns (project-specific)

## Current Implementation Status

### Already Implemented (tools/claude-hooks/)
- **Python**: black formatting, ruff linting
- **Rust**: cargo fmt
- **TypeScript/JavaScript**: prettier formatting  
- **Bash**: shellcheck validation, header requirements (set -euo pipefail, die function)
- **Dangerous patterns**: ((var++)) warnings

### Key Architecture
- PostToolUse hooks trigger after Write/Edit/MultiEdit
- Python package at ~/tools/claude-hooks
- Activated via hooks.json configuration
- Non-blocking for formatting, blocking for critical bash errors

## Phase 1: Critical Global Invariants (Immediate Priority)

These enforce rules from dot_claude/CLAUDE.md which is ALWAYS active across all projects. These are mechanical rules that can be automatically enforced.

**Note**: These items will be REMOVED from tools/CLAUDE.md (per deduplication analysis) as they're either global rules or can be mechanically enforced.

### 1.1 File Existence Validation
**Hook Type**: PreToolUse on Edit/MultiEdit
**Purpose**: Prevent editing non-existent files
**Implementation**:
```python
def validate_file_exists(file_path: str) -> tuple[bool, str]:
    if not Path(file_path).exists():
        return False, f"File {file_path} does not exist. Use Read tool first to verify, or Write to create new file."
    return True, ""
```

### 1.2 Python Version Enforcement  
**Hook Type**: PreToolUse on Bash
**Purpose**: Enforce Python 3.12 via uv/uvx
**Patterns to block**:
- `python script.py` or `python3 script.py` (without uvx)
- `pip install` or `pip3 install`
- `uvx python script.py` (no version specified)

**Suggest instead**:
- `uvx python@3.12 script.py`
- `uv add package` (not pip install)

### 1.3 Sudo Command Prevention
**Hook Type**: PreToolUse on Bash
**Purpose**: Block sudo execution
**Implementation**:
```python
def block_sudo(command: str) -> tuple[bool, str]:
    if command.strip().startswith("sudo"):
        # Exception for PowerShell in WSL
        if "powershell" in command:
            return True, ""
        return False, f"Cannot execute sudo commands. Please run this yourself:\n{command}"
    return True, ""
```

### 1.4 Documentation Creation Control
**Hook Type**: PreToolUse on Write
**Purpose**: Prevent unsolicited documentation
**Rules**:
- wip-claude/* files: Always allow
- *.md files elsewhere: Warn if not requested
- Enforce YYYYMMDD_HHMMSS format for wip-claude files

## Phase 2: High-Impact Quality Improvements

These patterns come from tools/CLAUDE.md but represent enforceable quality checks rather than philosophy.

### 2.1 Test Quality Validators
**Hook Type**: PostToolUse on Write/Edit for test files
**Purpose**: Prevent ineffective tests (the "OCR 0% problem")
**Detect**:
- Files matching: *_test.py, test_*.py, *.test.ts
- Structure-only assertions: `assert result.is_valid`, `assert result is not None`
- Missing concrete value checks

### 2.2 Bash Script Completeness
**Extend current validators with**:
- Check for --test flag implementation
- Verify IFS=$'\n\t' setting
- Check DEBUG="${DEBUG:-0}" pattern
- Suggest bats-core tests if missing

### 2.3 Package Manager Enforcement
**Additional Python checks**:
- Block poetry/pipenv commands
- Verify .python-version file = "3.12"
- Check pyproject.toml has requires-python = ">=3.12"

## Phase 3: Standards and Patterns

### 3.1 Documentation Patterns
- **ABOUTME validator**: Check files start with 2-line descriptive comment
- **README structure**: Ensure Quick Start/Commands section at top

### 3.2 Repository Standards  
- **Install paths**: Validate executables go to ~/.local/bin/
- **Data storage**: Check ~/.local/share/<tool-name>/ pattern

### 3.3 Refactoring Discipline
- Detect "refactor" in user request
- Monitor for behavior changes during refactoring
- Flag "while I'm here" additions

### 3.4 Commit Message Validation
- Enforce: `type(scope): description`
- Valid types: feat, fix, docs, style, refactor, test, chore

## Hook Configuration Structure

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "^(Edit|MultiEdit)$",
        "hooks": [{
          "type": "command",
          "command": "uvx --from ~/tools/claude-hooks claude-hooks validate-file-exists"
        }]
      },
      {
        "matcher": "^Bash$",
        "hooks": [
          {
            "type": "command",
            "command": "uvx --from ~/tools/claude-hooks claude-hooks check-python-usage",
            "condition": "command_matches:^python[3]?\\s+"
          },
          {
            "type": "command",
            "command": "uvx --from ~/tools/claude-hooks claude-hooks block-sudo",
            "condition": "command_starts_with:sudo"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "^(Write|Edit|MultiEdit)$",
        "hooks": [{
          "type": "command",
          "command": "uvx --from ~/tools/claude-hooks claude-hooks validate-tests",
          "condition": "file_pattern:*test*.py"
        }]
      }
    ]
  }
}
```

## Implementation Notes

### Design Principles
1. **Fail fast on critical issues** (sudo, missing files)
2. **Warn on quality issues** (test patterns, documentation)
3. **Auto-fix formatting** (already implemented)
4. **Provide clear guidance** in error messages

### Technical Considerations
- Use PreToolUse for blocking behaviors
- Use PostToolUse for quality checks and auto-fixes
- Keep validators focused and fast
- Make hook behavior configurable via environment variables

### Testing Strategy
1. Create test files for each validator
2. Use the test-hooks.sh script for integration testing
3. Test both positive (allow) and negative (block) cases
4. Ensure clear error messages that guide correct behavior

## Benefits of Full Implementation

1. **Enforced Consistency**: Critical patterns become impossible to violate
2. **Learning Reinforcement**: Hooks teach best practices through immediate feedback
3. **Reduced Review Burden**: Catch issues before they reach code review
4. **Better Claude Behavior**: Consistent codebase patterns improve Claude's responses
5. **Developer Experience**: Less mental overhead remembering all rules

## What NOT to Put in Hooks

Based on our separation of concerns, these should remain in tools/CLAUDE.md as philosophy/guidance:

1. **Language Selection Philosophy** - Requires judgment about project needs
2. **Development Operational Modes** - Complex behavioral patterns
3. **Refactoring Discipline** - Requires understanding intent
4. **Empirical Development Principle** - Philosophy about data vs theory
5. **Testing Philosophy** - The "why" behind test quality
6. **LLM-Specific Anti-Patterns** - Self-awareness guidance
7. **Plan Execution Discipline** - Complex workflow management

These require human judgment, understanding of context, or represent educational content that explains the "why" behind rules.

## Migration Path

1. Start with Phase 1 (critical blockers)
2. Gather feedback on hook behavior
3. Implement Phase 2 based on pain points
4. Phase 3 as time permits

## Related Documents

This plan works in conjunction with:
- **20250109_184500_tools_claude_md_deduplication_analysis.md** - Shows what to remove from tools/CLAUDE.md
- **20250109_185000_tools_claude_md_cleaned.md** - Cleaned version of tools/CLAUDE.md (~160 lines vs 286)

Archived/superseded:
- 20250109_161500_hooks_analysis.md (initial exploration)
- 20250109_claude_hooks_final.md (current state documentation)

Still useful for reference:
- 20250109_165000_claude_hooks_expansion_analysis.md (detailed pattern analysis)
- 20250109_180500_claude_hooks_expansion_opportunities.md (prioritized opportunities)