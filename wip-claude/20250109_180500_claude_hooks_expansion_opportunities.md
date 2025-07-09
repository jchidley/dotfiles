# Claude Hooks Expansion Opportunities
Created: 2025-01-09 18:05

## Overview

Analysis of enforceable invariants from dot_claude/CLAUDE.md (global config) and tools/CLAUDE.md that could be moved to Claude Code hooks.

**Key insights**: 
- dot_claude/CLAUDE.md is ALWAYS active - its rules should be prioritized for enforcement
- tools/CLAUDE.md should focus on philosophy and complex patterns that can't be mechanically enforced
- Hooks should handle all mechanical validation to reduce cognitive load

## Current Hook Implementation

Our claude-hooks system currently enforces:
- **Formatting**: black, ruff (Python), cargo fmt (Rust), prettier (JS/TS)
- **Bash validation**: shellcheck, header requirements (set -euo pipefail, die function)
- **Dangerous pattern detection**: ((var++)) warnings

## Critical Global Invariants (from dot_claude/CLAUDE.md)

### 1. File Existence Validation (PreToolUse on Edit/MultiEdit)

**Rule**: "VALIDATE file existence before editing"

**Implementation**:
- Hook on Edit/MultiEdit tools
- Verify file exists before allowing edit
- Suggest using Read tool first if file not found
- This prevents common Claude errors where it tries to edit non-existent files

### 2. Python Version Enforcement (PreToolUse on Bash)

**Rules**: 
- "ALWAYS use uv/uvx with Python 3.12"
- "Never use pip directly"

**Validators to add**:
- Block: `python script.py`, `python3 script.py` (without uvx)
- Block: `pip install`, `pip3 install`
- Suggest: `uvx python@3.12 script.py`, `uv add package`
- Check for .python-version file content = "3.12"

**Example patterns to block**:
```bash
# BLOCK these
python3 script.py
pip install requests
uvx python script.py  # No version specified

# SUGGEST these instead
uvx python@3.12 script.py
uv add requests
```

### 3. Sudo Command Prevention (PreToolUse on Bash)

**Rule**: "NEVER run sudo directly"

**Implementation**:
- Block any bash command starting with `sudo`
- Return message: "Cannot run sudo. Please run this command yourself: [command]"
- Exception: Allow `sudo powershell` for WSL scenarios

### 4. Documentation Creation Control (PreToolUse on Write)

**Rule**: "Creating unsolicited content - Only create what's requested"

**Validators**:
- For wip-claude/ files: Always allow (research/documentation)
- For *.md files: Warn if not explicitly requested
- Check file naming: wip-claude files must use YYYYMMDD_HHMMSS_description.md format

### 5. PowerShell WSL Pattern Enforcement (PreToolUse on Bash)

**Rules for PowerShell from WSL**:
- Must use `-Command` syntax, never `-File`
- Boolean parameters need backtick escaping

**Validators**:
- Block: `powershell -File script.ps1`
- Suggest: `powershell -Command "& {.\script.ps1}"`
- Check for proper boolean escaping: `-DryRun:`$false`

## High-Priority Expansion Opportunities (from tools/CLAUDE.md)

### 1. Test Quality Validators (PreToolUse/PostToolUse on Write/Edit for test files)

**Problem**: "OCR module had property tests, snapshot tests, integration tests, fuzz tests. Mutation testing revealed 0% effectiveness"

**Validators to add**:
- Detect test files by pattern (*_test.py, test_*.py, *.test.ts, etc.)
- Check for concrete value assertions vs structure-only checks
- Flag tests that only check: isValid, !== null, no property verification
- Warn about snapshot tests as primary verification method

**Example patterns to flag**:
```python
# BAD - structure only
assert result.is_valid
assert result is not None

# GOOD - value assertion
assert result.value == 42
assert result.error_message == "Invalid input"
```

### 2. Documentation Pattern Validators (PostToolUse on Write/Edit)

**ABOUTME Comment Validator**:
- Check new files start with 2-line ABOUTME comment
- Pattern: First non-empty lines should be comment with description

**README Structure Validator**:
- For README.md files, ensure "## Quick Start" or "## Commands" appears early
- Commands/usage should be at top, not buried in documentation

### 3. Python-Specific Validators (PreToolUse on Bash)

**Package Manager Enforcement**:
- Block/warn on: `pip install`, `poetry add`, `pipenv install`
- Suggest: `uv add` or `uvx` instead

**Error Handling Pattern Checker** (PostToolUse on Write/Edit for .py):
- Detect functions returning bare values that could fail
- Suggest Optional[T] or Union[T, Error] patterns
- Flag uncaught exceptions in non-test code

## Medium-Priority Opportunities

### 4. Bash Script Completeness (PostToolUse on Write for .sh)

**Self-Test Mode Validator**:
- Check for `--test` flag handling in argument parsing
- Warn if bats-core tests don't exist for the script

**Missing elements** (extend current validator):
- IFS=$'\n\t' setting
- DEBUG="${DEBUG:-0}" pattern

### 5. Repository Standards Validators (PreToolUse on Bash)

**Installation Path Checker**:
- For `install` commands, verify target is ~/.local/bin/
- For data storage, verify ~/.local/share/<tool-name>/ pattern

**Example patterns**:
```bash
# Flag these
sudo cp script /usr/local/bin/  # Wrong location
mkdir /tmp/myapp-data  # Wrong data location

# Suggest these
cp script ~/.local/bin/
mkdir -p ~/.local/share/myapp/
```

### 6. Refactoring Discipline Enforcer (Stop hook or context-aware PreToolUse)

**"While I'm Here" Detector**:
- Track when user mentions "refactor"
- Flag edits that change behavior (not just structure)
- Detect feature additions during refactoring tasks

**Patterns to detect**:
- Adding new parameters to functions
- Changing return types
- Adding new features/methods
- "Improving" logic beyond mechanical changes

## Low-Priority Opportunities

### 7. Commit Message Validator (PreToolUse on Bash matching git commit)

**Format Enforcement**:
- Pattern: `type(scope): description`
- Valid types: feat, fix, docs, style, refactor, test, chore
- Block commits not matching pattern

### 8. Language Selection Advisor (PreToolUse on Write for new files)

**Bash-First Principle**:
- When creating new scripts, suggest bash first
- Only escalate to Python/Rust if specific libraries needed
- Warn about over-engineering simple tasks

## What Should NOT Be In Hooks

These patterns from tools/CLAUDE.md should remain as guidance, not hooks:
- Language selection philosophy (bash-first principle)
- Development operational modes (Implementation, Refactoring)
- Testing philosophy (understanding the "why")
- Refactoring discipline (requires intent understanding)
- Plan execution patterns (complex workflows)
- LLM anti-patterns (self-awareness)

## Revised Priority Order

Based on the separation of concerns and dot_claude/CLAUDE.md being always active:

### Phase 1: Critical Global Invariants (Immediate)
1. **File existence validation** - Prevents common Edit errors
2. **Python version enforcement** - Critical for consistency 
3. **Sudo command prevention** - Security and workflow issue
4. **Documentation creation control** - Prevents unwanted file creation

### Phase 2: High-Impact Quality (Next Sprint)
1. **Test quality validators** - Addresses the "0% effectiveness" problem
2. **Bash script completeness** - Extends current validators
3. **Package manager enforcement** - Reinforces Python patterns

### Phase 3: Standards & Patterns (Future)
1. **Documentation patterns** (ABOUTME, README structure)
2. **Repository standards** (install paths, data storage)
3. **Refactoring discipline** enforcement
4. **Commit message validation**

## Implementation Strategy

1. **Extend validators.py** with new validation functions
2. **Add new hook configurations** in hooks.json for different tool matchers
3. **Create warning levels**: blocking errors vs advisory warnings
4. **Make validators configurable** via environment variables or config file
5. **Add PreToolUse hooks** for blocking behaviors (sudo, wrong Python)
6. **Use PostToolUse hooks** for quality checks (test assertions, documentation)

## Hook Configuration Examples

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "^(Edit|MultiEdit)$",
        "hooks": [
          {
            "type": "command",
            "command": "uvx --from ~/tools/claude-hooks claude-hooks validate-file-exists"
          }
        ]
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
          },
          {
            "type": "command",
            "command": "uvx --from ~/tools/claude-hooks claude-hooks check-pip-usage",
            "condition": "command_contains:pip install"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "^(Write|Edit|MultiEdit)$",
        "hooks": [
          {
            "type": "command",
            "command": "uvx --from ~/tools/claude-hooks claude-hooks validate-tests",
            "condition": "file_pattern:*test*.py"
          },
          {
            "type": "command", 
            "command": "uvx --from ~/tools/claude-hooks claude-hooks validate-wip-claude",
            "condition": "file_path:wip-claude/*"
          }
        ]
      }
    ]
  }
}
```

## Benefits

1. **Automated Standards Enforcement**: No need to remember all rules
2. **Early Error Detection**: Catch issues before they're committed
3. **Learning Tool**: Hooks teach best practices through feedback
4. **Consistency**: Same standards applied across all projects
5. **Reduced Cognitive Load**: Focus on solving problems, not formatting

## Next Steps

1. Prioritize test quality validators (highest impact based on CLAUDE.md emphasis)
2. Implement documentation pattern validators (easy wins)
3. Create Python-specific validators (common pain points)
4. Extend bash validators with additional checks
5. Add configuration system for enabling/disabling specific validators