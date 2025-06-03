# Claude Slash Commands Documentation

This document provides comprehensive documentation for all Claude slash commands. The actual command files in `~/.claude/commands/` contain only execution instructions for Claude.

## Command Categories

### Session Management
Commands for managing Claude work sessions and maintaining context.

#### /start
**Author**: Jack Chidley  
**Created**: 2025-05-25  
**Purpose**: Initialize a Claude session with proper context loading

Loads project context from HANDOFF.md and SESSION_*.md files to restore state from previous sessions. Essential for maintaining continuity across work sessions.

**Usage**: Run at the beginning of each new Claude session
**Prerequisites**: HANDOFF.md should exist in the project directory

#### /checkpoint
**Author**: Jack Chidley  
**Created**: 2025-05-25  
**Purpose**: Quick state capture and reflection during work

Maintains a lightweight HANDOFF.md in your project directory. Use at cognitive milestones:
- ✅ Completed a meaningful chunk of work
- 💡 Discovered something important
- 🔄 About to switch focus/context
- 🤔 Feeling stuck or confused
- 📊 Context usage approaching 40%

The 2-minute process involves quick reflection, updating HANDOFF.md, and capturing breakthroughs in PROJECT_WISDOM.md if significant insights emerge.

#### /wrap-session
**Author**: Jack Chidley  
**Created**: 2025-05-25  
**Purpose**: Archive current session and prepare for next time

Creates a comprehensive session log, updates HANDOFF.md with latest state, and provides Git commit reminders. Ensures smooth handoff for the next session.

**Prerequisites**:
- HANDOFF.md exists and is current
- Work is at a logical stopping point
- Key insights have been captured

### Planning Commands
Commands for planning and organizing work.

#### /plan
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Create a structured development plan

Generates a detailed implementation plan with requirements, constraints, and implementation approach. Plans are stored in `~/.claude/plans/[project-name]/plan_[timestamp].md`.

#### /plan-tdd
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Create a Test-Driven Development focused plan

Similar to /plan but emphasizes test-first development approach. Includes test strategy and coverage requirements.

#### /plan-gh
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Create a plan integrated with GitHub issues

Creates development plans that reference and integrate with GitHub issues for better project tracking.

#### /brainstorm
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Iterative brainstorming process

Facilitates creative problem-solving through iterative exploration of ideas and solutions.

### Execution Commands
Commands for executing planned work.

#### /do-todo
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Execute tasks from TODO list

Systematically works through tasks in TODO.md file, updating status as work progresses.

#### /do-plan
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Execute a development plan

Takes a structured plan and executes it step by step, ensuring all requirements are met.

#### /do-prompt-plan
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Execute plan from user prompt

Creates and executes a plan based on user's direct input rather than a formal plan document.

#### /do-issues
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Work through project issues

Systematically addresses issues listed in ISSUES.md or GitHub issues.

#### /do-file-issues
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Address file-specific issues

Focuses on issues within specific files, useful for targeted refactoring or bug fixes.

### Issue Management
Commands for managing and creating issues.

#### /gh-issue
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Create GitHub issues workflow

Helps create well-structured GitHub issues with proper labels, descriptions, and acceptance criteria.

#### /make-github-issues
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Generate GitHub issues from code analysis

Analyzes codebase and creates GitHub issues for improvements, bugs, or technical debt.

#### /make-local-issues
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Generate local ISSUES.md from code analysis

Similar to make-github-issues but creates a local ISSUES.md file instead of GitHub issues.

#### /find-missing-tests
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Identify code lacking test coverage

Scans codebase to find functions, methods, and modules that lack corresponding tests.

### Requirements Management
Commands for managing project requirements.

#### /req
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Manage project requirements

Provides subcommands for requirement management:
- `/req check <description>` - Check if something qualifies as a project requirement
- `/req add <description>` - Add a new project requirement to REQUIREMENTS.md
- `/req list` - List all current requirements
- `/req status <REQ-XXXX>` - Check status of a specific requirement

Distinguishes between project requirements (tracked) and regular tasks (not tracked).

#### /req-to-issue
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Convert requirements to GitHub issues

Creates detailed GitHub issues from requirements in REQUIREMENTS.md, ensuring proper tracking and implementation documentation.

### Utility Commands
General utility and setup commands.

#### /setup
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Initialize project environment

Sets up Python environment, creates necessary directories, and establishes project structure.

#### /session-summary
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Generate session summary

Creates a concise summary of work completed during the current session.

#### /security-review
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Perform comprehensive security audit

Executes an actionable security review workflow that:
- Identifies project type and technology stack
- Scans for hardcoded secrets and credentials using regex patterns
- Checks dependencies for known vulnerabilities
- Searches for dangerous code patterns (SQL injection, command injection, etc.)
- Reviews authentication and authorization implementations
- Audits input validation and file operations
- Examines configuration files for security issues
- Generates detailed SECURITY_REVIEW report with findings by severity

The command uses grep and glob tools to systematically search for security anti-patterns and produces actionable remediation guidance.

#### /tool
**Author**: Jack Chidley  
**Created**: 2025-05-25  
**Purpose**: Access development standards

Directs to comprehensive development standards documentation at `/home/jack/tools/CLAUDE.md`.

## Command Workflow Integration

The recommended workflow for multi-session development:

```
/start → work → /checkpoint → work → /wrap-session
  ↑                                         ↓
  └───────── Next Session ←──────────────┘
```

For new features:
1. `/req check` - Verify if it's a requirement
2. `/req add` - Add to REQUIREMENTS.md
3. `/plan` or `/plan-tdd` - Create implementation plan
4. `/do-plan` - Execute the plan
5. `/checkpoint` - Save progress
6. `/req-to-issue` - Create GitHub tracking

## File Structure

When deployed by chezmoi:
- `~/.claude/COMMANDS.md` - This documentation file
- `~/.claude/commands/*.md` - Individual command execution instructions
- `~/.claude/plans/` - Generated development plans
- `~/.claude/sessions/` - Archived session logs

## Best Practices

1. Always `/start` at the beginning of a session
2. Use `/checkpoint` at natural breaking points
3. Always `/wrap-session` before ending work
4. Use `/req` commands for new feature requests
5. Prefer `/plan-tdd` for new feature development
6. Use `/security-review` before committing sensitive changes

## Built-in Claude Code Commands

In addition to custom `/project:*` commands, these built-in commands are available:
- `/pr_comments` - View pull request comments
- `/review` - Request code review
- `/status` - View account and system statuses
- `/memory` - Open memory files in editor
- `/terminal-setup` - Install Shift+Enter key binding for newlines
- `/compact` - Clear conversation while keeping files
- `/clear` - Full reset of conversation and context

## Implementation Notes

Commands should be written as direct instructions to Claude without explanatory text. Each command file should assume Claude has access to:
- All project files via Read/Write tools
- Git operations via Bash
- Context from HANDOFF.md and SESSION logs
- This documentation for understanding command purposes