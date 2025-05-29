# Project: Chezmoi Dotfiles
Updated: 2025-05-29 17:33

## Current State
Status: Cleaned up .chezmoiignore and CLAUDE.md files
Target: Minimal, focused configuration files
Latest: Refactored CLAUDE.md files to ~25 lines each, moved docs to CLAUDE_METHODOLOGY.md

## Essential Context
- Removed Claude runtime data (projects/, todos/, statsig/) from chezmoi
- CLAUDE.md now excluded from deployment - only applies in chezmoi directory
- Global CLAUDE.md reduced from 109 to 25 lines
- Created CLAUDE_METHODOLOGY.md for documentation/credits

## Next Step
Commit the cleanup changes to git

## Related Documents
- CLAUDE.md - Project-specific instructions
- dot_claude/CLAUDE.md - Global configuration
- dot_claude/CLAUDE_METHODOLOGY.md - Full documentation
- SESSION_20250529_150000.md - Current session log