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

**MANDATORY: Always use uv/uvx for ALL Python operations with inline script metadata**

### 1. Core Rule - Every Python Script MUST Have This Header

```python
#!/usr/bin/env python3
# /// script
# dependencies = [
#   "requests",
#   "pandas>=2.0",
# ]
# requires-python = ">=3.12"
# ///

import requests
import pandas as pd
```

**This PEP 723 metadata is REQUIRED for every standalone Python script - no exceptions.**

### 2. Execution Rules

**For scripts with inline dependencies:**
```bash
uv run script.py            # ALWAYS use this
uv run script.py --args     # With arguments
```

**For ephemeral tool execution:**
```bash
uvx ruff check              # One-time tool run
uvx --python 3.12 mypy .    # Specify Python version
```

**FORBIDDEN - Never use these:**
```bash
python script.py            # ❌ WRONG
python3 script.py          # ❌ WRONG  
./script.py                # ❌ WRONG
pip install anything       # ❌ WRONG
source venv/bin/activate   # ❌ WRONG
```

### 3. Decision Tree

1. **Creating/editing a Python script?** → Add PEP 723 header
2. **Running a local script?** → Use `uv run`
3. **Running a tool once?** → Use `uvx`
4. **Installing a tool permanently?** → Use `uv tool install`
5. **Need specific Python version?** → Use `uvx python@3.12`

### 4. Tool Management

```bash
# Install development tools permanently
uv tool install ruff mypy black pytest pre-commit

# Run ephemeral tools
uvx ruff check
uvx mypy src/

# Run with specific Python
uvx --python 3.12 pytest
```

### 5. Project Management (for full projects, not single scripts)

```bash
# Initialize project (creates pyproject.toml)
uv init

# Add dependencies to project
uv add pandas numpy

# Run in project context
uv run python main.py
```

**In pyproject.toml:**
```toml
requires-python = ">=3.12"
```

### 6. Conversion Checklist

When updating existing Python scripts:
- [ ] Add shebang: `#!/usr/bin/env python3`
- [ ] Add PEP 723 metadata block after shebang
- [ ] List ALL non-stdlib imports in dependencies
- [ ] Set `requires-python = ">=3.12"`
- [ ] Remove any pip install instructions
- [ ] Update execution commands to use `uv run`

### 7. Common Patterns

**Data analysis script:**
```python
#!/usr/bin/env python3
# /// script
# dependencies = [
#   "pandas",
#   "matplotlib",
#   "seaborn",
# ]
# requires-python = ">=3.12"
# ///
```

**Web scraping script:**
```python
#!/usr/bin/env python3
# /// script
# dependencies = [
#   "requests",
#   "beautifulsoup4",
#   "lxml",
# ]
# requires-python = ">=3.12"
# ///
```

**CLI tool:**
```python
#!/usr/bin/env python3
# /// script
# dependencies = [
#   "click",
#   "rich",
# ]
# requires-python = ">=3.12"
# ///
```

### Why This Matters
- **Reproducibility**: Scripts work identically everywhere
- **No environment pollution**: No global pip installs
- **Version consistency**: Always Python 3.12+
- **Zero setup**: `uv run` handles everything automatically

**Remember: If it imports non-stdlib modules, it MUST have inline metadata.**

