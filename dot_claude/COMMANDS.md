# Claude Slash Commands Documentation

This document provides comprehensive documentation for all Claude slash commands. The actual command files in `~/.claude/commands/` contain only execution instructions for Claude.

**Note**: Claude now has built-in planning mode and todo management (TodoRead/TodoWrite). Use these native features instead of file-based planning commands.

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

### Issue Management
Commands for managing and creating issues.

#### /make-github-issues
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Generate GitHub issues from code analysis

Analyzes codebase and creates GitHub issues for improvements, bugs, or technical debt.

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
General utility and analysis commands.

#### /security-review
**Author**: Jack Chidley  
**Created**: 2025-05-25  
**Purpose**: Perform comprehensive security audit of codebase

Analyzes the entire codebase for security vulnerabilities including:
- SQL injection risks
- XSS vulnerabilities
- Authentication/authorization issues
- Cryptographic weaknesses
- Configuration security
- Dependency vulnerabilities
- Input validation problems

Generates a detailed security report with severity ratings and remediation suggestions.

**Usage**: Run periodically or before major releases
**Output**: Security report in PROJECT_SECURITY_REVIEW.md

#### /tool
**Author**: Unknown  
**Created**: 2025-05-01  
**Purpose**: Load development standards from tools/CLAUDE.md

Reads comprehensive development standards including system architecture patterns, language-specific guidelines, and workflow standards.

#### /standards
**Author**: Jack Chidley  
**Created**: 2025-06-30  
**Purpose**: Check project compliance with CLAUDE.md standards

Analyzes the current project against all CLAUDE.md standards and creates a plan to fix any violations. Checks:
- Global configuration standards (~/.claude/CLAUDE.md)
- Project-specific standards (./CLAUDE.md if exists)
- Development standards (/home/jack/tools/CLAUDE.md)

Generates a compliance report showing what's properly followed, what's violated, and what needs improvement. If violations are found, uses built-in planning mode to create an implementation plan prioritizing critical issues.

**Usage**: Run to audit project standards compliance
**Output**: Compliance report and remediation plan if needed

## Workflow Summary

The core workflow uses three essential commands:
1. **`/start`** - Begin work session
2. **`/checkpoint`** - Save progress during work
3. **`/wrap-session`** - End work session

Additional commands provide specialized functionality for requirements tracking, security analysis, and code quality assessment.

For planning tasks, use Claude's built-in planning mode. For todo management, use the native TodoRead and TodoWrite tools.