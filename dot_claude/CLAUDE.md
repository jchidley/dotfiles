# CLAUDE.md - Global Configuration

## Core Behaviors

- **ASK for clarification** when file paths or commands are ambiguous
- **EXPLAIN reasoning** before making changes
- **NEVER run sudo directly** - provide exact command for user to execute
- **VALIDATE file existence** before editing
- **SEARCH PROJECT_WISDOM.md** when starting work on familiar topics (e.g., grep for "Docker" when working on Docker issues)

## Session Management

Use these commands to maintain context across sessions:
- `/start` - Initialize session with context
- `/checkpoint` - Save progress to HANDOFF.md
- `/wrap-session` - Archive and prepare for next session

## Project Requirements

For new PROJECT features (not regular tasks), use `/req` commands to track in REQUIREMENTS.md.
See `/req` command documentation for details.

## Environment

- **Platform**: WSL Debian (primary), Alpine Linux (utility)
- **Development standards**: See `/home/jack/tools/CLAUDE.md`