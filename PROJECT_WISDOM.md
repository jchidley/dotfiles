# PROJECT_WISDOM.md - Chezmoi Dotfiles

Refined patterns distilled from 25+ sessions through repetition analysis.

## CORE PATTERNS (6+ occurrences)

### 🔷 Chezmoi Source File Discipline (used 7+ times across sessions)
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
**Evolution**: First seen 2025-06-30, reinforced in multiple sessions with TTY and PATH modifications

### 🔷 Command Instruction Detail (used 6+ times across sessions)
**When to use**: Writing or updating Claude Code slash commands
**Pattern**:
```markdown
# Detailed step-by-step instructions
1. Validate input with specific patterns
2. Check prerequisites with exact commands
3. Handle edge cases explicitly
4. Provide comprehensive error messages
5. Include specific examples and decision trees
```
**Why it works**: Command effectiveness directly correlates with instruction detail. Sparse commands (30 lines) fail, detailed commands (200+ lines) succeed.
**Failed alternatives**: Brief instructions, assuming Claude will infer steps
**Evolution**: First seen 2025-06-02 with /req command, validated across multiple command improvements

### 🔷 Working Directory Management (used 6+ times across sessions)
**When to use**: Any session management command that creates/reads project files
**Pattern**:
```markdown
IMPORTANT: Change to project root directory before file operations.
Use the working directory from the environment info as the project root.
```
**Why it works**: Prevents session files scattered across subdirectories when Claude navigates during work.
**Failed alternatives**: Assuming current directory is always project root, using relative paths
**Evolution**: First seen 2025-07-01, systematically applied to all session commands 2025-07-02

## ESTABLISHED PATTERNS (3-5 occurrences)

### **Session File Management** (used 5 times)
**When to use**: Checkpoint and wrap-session operations
**Pattern**:
- Use timestamped filenames to prevent overwrites: `SESSION_CHECKPOINT_HHMMSS.md`
- Read content before deletion to preserve context
- Use glob patterns `SESSION_*.md` to catch all checkpoint files
- Incorporate all checkpoint content into final session log

### **Claude Code Native Feature Usage** (used 4 times)
**When to use**: Before creating custom slash commands
**Pattern**: Check if Claude Code has built-in tools first (exit_plan_mode, TodoRead/TodoWrite, etc.)
**Impact**: Reduced command count from 20 to 9 by leveraging native features instead of reimplementing

### **DRY Principle Application** (used 4 times)
**When to use**: Multiple commands share identical instruction blocks
**Pattern**: Extract shared patterns to reference files that commands can point to
**Example**: Created wisdom-triggers.md as single source for wisdom capture patterns

### **TTY Error Handling in WSL** (used 4 times)
**When to use**: Automated chezmoi operations in WSL environments
**Pattern**: Always use `chezmoi apply --force` to bypass TTY requirements
**Context**: WSL environments lack proper TTY for interactive prompts

## EMERGING PATTERNS (1-2 occurrences)

### Path Precedence in Environment Variables (seen twice)
**Pattern**: PATH modifications in templates require careful ordering to maintain precedence
**Context**: Adding Go bin directory while preserving existing tool priorities

### Windows Terminal Command Standardization (seen twice)
**Pattern**: Standardize wt.exe commands using `-t 1` instead of `-t 0` for tab targeting
**Context**: Consistent behavior across bash and PowerShell environments

## ANTI-PATTERNS TO AVOID

### Nested dot_ Structures in Chezmoi
**Problem**: Creating `dot_claude/dot_claude/` results in `~/.claude/.claude/`
**Solution**: Use dot_ prefix only at top level

### Buried Conditional Logic in Commands
**Problem**: Important actions hidden in "if significant discovery" conditions
**Solution**: Make critical actions explicit steps with clear prompts

### Single Checkpoint Filenames
**Problem**: Multiple checkpoints overwrite each other
**Solution**: Use timestamped filenames for all checkpoint files

### Manual File Synchronization
**Problem**: Trying to manually sync chezmoi source and deployed files
**Solution**: Always edit source files and use chezmoi apply

## EMPIRICALLY VALIDATED CONSTANTS

- `chezmoi apply --force` resolves WSL TTY errors
- `-t 1` for Windows Terminal tab targeting (not `-t 0`)
- SESSION_*.md glob pattern catches all checkpoint variations
- Environment working directory = reliable project root reference