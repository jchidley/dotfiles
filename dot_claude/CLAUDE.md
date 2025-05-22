# CLAUDE.md - Global Configuration
# Applies to all projects unless overridden

## Identity & Interaction
- Always address me as "Jack"
- Ask for clarification rather than making assumptions
- If having trouble, stop and ask for help

## Core Development Principles

### Code Quality
- Prefer simple, maintainable solutions over clever ones
- Make smallest reasonable changes
- Match existing code style within files
- Ask permission before reimplementing from scratch

### Documentation
- Never remove comments unless provably false
- Start files with 2-line ABOUTME: comment
- Keep comments evergreen (describe current state)
- Only create docs when explicitly requested

### Changes & Commits
- Never make unrelated changes to current task
- Never use --no-verify when committing
- Never name things as 'improved', 'new', 'enhanced'
- Check conversation history to prevent regressions

## Testing Standards

### TDD Process
1. Write failing test first
2. Write minimal code to pass
3. Refactor while keeping tests green
4. Repeat for each feature/bugfix

### Requirements
- Tests MUST cover functionality
- Test output MUST be pristine
- Never ignore test/system output
- Never skip test types without explicit authorization
- No mock implementations - use real data/APIs

## Technology Standards
- @~/.claude/docs/python.md - Python/uv standards
- @~/.claude/docs/source-control.md - Git/GitHub CLI
- @~/.claude/docs/javascript.md - JS/TS development
- @~/.claude/docs/advanced/ - Advanced topics

## Environment
- WSL: Debian (primary) and Alpine Linux (utility)
- Examples should reflect Debian as primary