# Project: Chezmoi Dotfiles
Updated: 2025-05-29

## Current State
Status: Clarified dual-track requirements approach
Target: Lean REQUIREMENTS.md for Claude context + detailed GitHub issues
Latest: Confirmed design philosophy for requirement tracking

## Essential Context
- REQUIREMENTS.md stays lean for Claude Code context preservation:
  - Just REQ-XXXX, name, priority, status, issue link
  - Brief description and rationale only
  - Points to GitHub for all implementation details
- GitHub issues hold comprehensive implementation info:
  - Design decisions, technical approach, code examples
  - Progress tracking, test strategies, documentation
  - All detailed work happens in GitHub, not local files
- `/req` commands already implement this dual-track approach correctly

## Next Step
Continue using the enhanced /req workflow as designed - lean local files, detailed GitHub issues

## Related Documents
- CLAUDE.md - Project-specific instructions
- dot_claude/commands/req.md - Requirements command (dual-track design)
- dot_claude/commands/req-to-issue.md - GitHub issue creation
- CLAUDE_COMMANDS_LOG.md - Session history