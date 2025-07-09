# PROJECT_WISDOM.md - Chezmoi Dotfiles

Refined patterns distilled from 32 sessions through repetition analysis.

## CORE PATTERNS (6+ occurrences)

### 🔷 Chezmoi Source File Discipline (used 10+ times across sessions)
**When to use**: Any time editing configuration files managed by chezmoi
**Pattern**:
```bash
# For humans: Use chezmoi edit command
chezmoi edit ~/.bashrc        # ✅ Correct
vim ~/.bashrc                 # ❌ Wrong - changes lost on next apply

# For Claude: Edit source files directly with Read/Edit/Write tools
# ✅ Correct: /home/jack/.local/share/chezmoi/dot_bashrc.tmpl
# ❌ Wrong: ~/.bashrc (deployed file)
```
**Why it works**: Chezmoi deploys from source to target. Direct edits to deployed files are overwritten on next `chezmoi apply`. The directory structure principle applies to both humans and Claude - always work with source files.
**Failed alternatives**: Editing deployed files directly, manual sync between source/target
**Evolution**: First seen 2025-01-06, reinforced across all sessions involving config changes

### 🔷 Working Directory Management (used 8+ times across sessions)
**When to use**: Any session management command that creates/reads project files
**Pattern**:
```markdown
IMPORTANT: Change to project root directory before file operations.
Use the working directory from the environment info as the project root.

cd <working directory from environment info>
```
**Why it works**: Prevents session files scattered across subdirectories when Claude navigates during work. Environment working directory is fixed at Claude start.
**Failed alternatives**: Using "project root" terminology (ambiguous), assuming current directory, relative paths
**Evolution**: First seen 2025-07-01, systematically applied to all commands 2025-07-02, validated 2025-01-05

### 🔷 Command Instruction Detail (used 7+ times across sessions)
**When to use**: Writing or updating Claude Code slash commands
**Pattern**:
```markdown
# Detailed step-by-step instructions with:
1. Explicit validation patterns
2. Exact prerequisite commands
3. Edge case handling
4. Comprehensive error messages
5. Specific examples and decision trees
6. No ambiguous terms like "project root"
```
**Why it works**: Command effectiveness directly correlates with instruction detail. Sparse commands fail, detailed commands (200+ lines) succeed.
**Failed alternatives**: Brief instructions, assuming Claude will infer steps, using ambiguous references
**Evolution**: First seen with /req command, validated across checkpoint, wrap-session, clean-wisdom

### 🔷 Separation of Concerns in Commands (used 6+ times)
**When to use**: Building slash commands with shared patterns
**Pattern**:
```markdown
# Commands contain procedural instructions
# Reference files contain domain knowledge
# Example: wisdom-triggers.md referenced by multiple commands

Commands focus on: HOW to execute
Reference files contain: WHAT to look for
```
**Why it works**: DRY principle - change once, apply everywhere. Ensures consistency across commands.
**Failed alternatives**: Duplicating wisdom patterns in checkpoint.md and wrap-session.md
**Evolution**: Discovered 2025-07-02, immediately applied to wisdom capture system

## ESTABLISHED PATTERNS (3-5 occurrences)

### **Session File Management** (used 5 times)
**When to use**: Checkpoint and wrap-session operations
**Pattern**:
```bash
# Use timestamped filenames to prevent overwrites
SESSION_CHECKPOINT_HHMMSS.md
SESSION_${TIMESTAMP}.md

# Read content before deletion to preserve context
# Use glob patterns to catch all variations
SESSION_*.md
```
**Why it works**: Prevents data loss from overwrites, preserves all checkpoint content
**Evolution**: Single filename → timestamped → glob pattern matching

### **TTY Error Handling in WSL** (used 5 times)
**When to use**: Automated chezmoi operations in WSL environments
**Pattern**:
```bash
chezmoi apply --force  # ✅ Bypasses TTY requirements
chezmoi apply         # ❌ May fail with TTY errors in WSL
```
**Context**: WSL environments lack proper TTY for interactive prompts
**Evolution**: Discovered through multiple failed applies, --force flag validated as solution

### **Claude Code Native Feature Usage** (used 4 times)
**When to use**: Before creating custom slash commands
**Pattern**: 
```markdown
Check native features first:
- exit_plan_mode for planning
- TodoRead/TodoWrite for task tracking
- Built-in research mode
```
**Impact**: Reduced command count from 20 to 9 by leveraging native features
**Evolution**: Gradual discovery of native features, systematic removal of redundant commands

### **Windows Terminal Command Standardization** (used 3 times)
**When to use**: Cross-platform terminal commands
**Pattern**:
```bash
wt.exe -t 1 "command"  # ✅ Consistent tab targeting
wt.exe -t 0 "command"  # ❌ Inconsistent behavior
```
**Context**: Ensures reliable behavior across bash and PowerShell environments

## EMERGING PATTERNS (1-2 occurrences)

### Claude Code Hooks Architecture (seen 2 times)
**Pattern**: Pre/Post tool use hooks for enforcing standards automatically
**Context**: Moving mechanical validation from CLAUDE.md to automated hooks
**Potential**: Could expand to validate test quality, bash completeness, documentation

### System Timestamp Usage (seen 2 times)
**Pattern**: Use `date` command for timestamps instead of placeholders
```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M")
```
**Context**: /wrap-session and /checkpoint need real timestamps

### Cross-Project Wisdom Analysis (seen once)
**Pattern**: Analyze PROJECT_WISDOM.md across subdirectories for common patterns
**Potential**: Identify patterns worth promoting to global wisdom

## ANTI-PATTERNS TO AVOID

### Nested dot_ Structures in Chezmoi
**Problem**: Creating `dot_claude/dot_claude/` results in `~/.claude/.claude/`
**Solution**: Use dot_ prefix only at top level

### Direct File Editing Instead of Chezmoi
**Problem**: Editing ~/.bashrc directly loses changes on next apply
**Solution**: Always use chezmoi edit or edit source files

### Ambiguous Directory References
**Problem**: "Project root" interpreted differently by Claude
**Solution**: Use explicit "working directory from environment info"

### Buried Critical Actions
**Problem**: Important actions hidden in conditional logic
**Solution**: Make critical actions explicit steps with clear prompts

### Manual File Synchronization
**Problem**: Trying to manually sync chezmoi source and deployed files
**Solution**: Trust chezmoi's deployment model

## EMPIRICALLY VALIDATED CONSTANTS

- `chezmoi apply --force` resolves WSL TTY errors consistently
- `-t 1` for Windows Terminal tab targeting (not `-t 0`)
- SESSION_*.md glob pattern catches all checkpoint variations
- Environment working directory = reliable project root reference
- 200+ line commands succeed, 30 line commands fail
- Phase 1 hooks prevent common errors (file existence, Python 3.12, sudo)

## META-INSIGHTS

### Command Evolution Pattern
Commands evolve through: Discovery → Documentation → Refinement → Minimal viable version
Example: 20 commands → 9 commands through native feature discovery

### Wisdom Capture Maturity
Evolution: Ad-hoc insights → PROJECT_WISDOM.md → /clean-wisdom distillation → Pattern emphasis by frequency

### Documentation as Living System
Commands and documentation co-evolve based on usage patterns and pain points