# CLAUDE.md - Global Configuration

## Core Behaviors

- **ASK for clarification** when file paths or commands are ambiguous
- **EXPLAIN reasoning** before making changes
- **NEVER run sudo directly** - provide exact command for user to execute
- **VALIDATE file existence** before editing

## Universal Anti-Patterns

❌ **Acting without explaining** - Always state what you're about to do
❌ **Making changes without verification** - Check before editing
❌ **Switching tasks without user trigger** - Stay focused on current task
❌ **Assuming instead of asking** - When uncertain, ask for clarification
❌ **Creating unsolicited content** - Only create what's requested

## Documentation

**Create temporary documentation in `wip-claude/` folder** at project root when asked to document work or when documentation would be helpful for complex tasks.

**File naming**: Use timestamp format `YYYYMMDD_HHMMSS_description.md`
- Example: `20250106_143000_code_review.md`

**Content guidelines**:
- Write for dual audience: Claude instructions AND human readability
- Include clear context, reasoning, and actionable steps
- Reference relevant files and documentation

## Research Mode

**Triggers**: "research", "investigate", "analyze", "find out"
**Actions**: Create `wip-claude/YYYYMMDD_HHMMSS_*_research.md`, investigate ONLY
**Exit**: User provides next instruction

**Note**: Planning mode is now handled by Claude's built-in planning features. Use the native planning mode when users request plans.

## Thinking Triggers

- **Ambiguous request**: "think about user intent"
- **Multiple valid approaches**: "think about trade-offs"
- **Conflicting information**: "think hard about which source to trust"
- **No clear path forward**: "ultrathink about alternatives"

## Project Requirements

For new PROJECT features (not regular tasks), use `/req <description>` to track in REQUIREMENTS.md.
- `/req <description>` - Add new requirement (checks for duplicates)
- `/req list` - View all requirements
- `/req status REQ-XXXX` - View specific requirement

## PowerShell Script Requirements (WSL)

**Critical patterns when calling PowerShell from WSL:**

1. **Navigate to WSL path first:**
   ```bash
   cd \\wsl.localhost\Debian\home\jack\tools\project-name
   ```
   **Why:** PowerShell can't find scripts without the full WSL path

2. **Use `-Command` syntax, never `-File`:**
   ```powershell
   # CORRECT
   sudo powershell -ExecutionPolicy Bypass -Command "& {.\script.ps1 -DryRun:`$false}"
   
   # WRONG
   sudo powershell -ExecutionPolicy Bypass -File ".\script.ps1"
   ```
   **Why:** `-File` fails with sudo and can't handle boolean parameters properly

3. **Start-Transcript in every script:**
   ```powershell
   # At script start
   Start-Transcript -Path ".\output-log.txt" -Force
   
   # At script end
   Stop-Transcript
   ```
   **Why:** Write-Host output bypasses normal redirection and gets lost without transcript

**Additional notes:**
- Boolean parameters need backtick escaping: `-DryRun:`$false`
- Requires Windows sudo: `scoop install sudo`

## Python Requirements

**Critical patterns for Python usage:**

1. **ALWAYS use uv/uvx with Python 3.12:**
   ```bash
   # CORRECT - Use uvx with Python 3.12
   uvx python@3.12 script.py
   
   # CORRECT - Default to Python 3.12
   uvx --python 3.12 python script.py
   
   # WRONG - Direct python call or unspecified version
   python3 script.py
   uvx python script.py  # May use wrong version
   ```
   **Why:** Ensures consistent Python 3.12 environment across all operations

2. **Check Python location with which:**
   ```bash
   # Always verify Python path on Debian
   which python3
   # Typically: /usr/bin/python3
   ```
   **Why:** Debian uses `python3` command, not `python`

3. **Running Python tools:**
   ```bash
   # CORRECT - Ephemeral tool execution
   uvx ruff check
   uvx mypy src/
   
   # CORRECT - Install persistent tools
   uv tool install ruff
   uv tool install pre-commit
   ```
   **Why:** uvx runs tools in isolated environments, preventing conflicts

4. **Project Python management:**
   ```bash
   # ALWAYS create virtual environment with Python 3.12
   uv venv --python 3.12
   
   # Run within project context (uses .python-version or venv)
   uv run python script.py
   uv run pytest
   
   # Ensure Python 3.12 in pyproject.toml
   # requires-python = ">=3.12"
   ```
   **Why:** `uv run` automatically manages virtual environments

**Additional notes:**
- Never use pip directly - use `uv pip` instead
- For project dependencies: `uv add package` not `pip install`
- uv automatically downloads Python 3.12 if not available
- Always specify `requires-python = ">=3.12"` in pyproject.toml
- Use `.python-version` file with content `3.12` for project consistency

