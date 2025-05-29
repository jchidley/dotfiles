# Project: Chezmoi Dotfiles
Updated: 2025-05-29

## Current State
Status: Complete /req command with REQUIREMENTS.md management
Target: Full requirement tracking in files AND GitHub issues
Latest: Enhanced both file management and GitHub integration

## Essential Context
- `/req add` now properly manages REQUIREMENTS.md files:
  - Creates from template if needed
  - Adds requirements with proper REQ-XXXX numbering
  - Saves to project's REQUIREMENTS.md
- `/req list` and `/req status` work with local REQUIREMENTS.md
- `/req-to-issue` creates detailed GitHub issues AND updates REQUIREMENTS.md
- Complete workflow: Add to file → Create issue → Link back to file
- All commands check for REQUIREMENTS.md in current directory

## Next Step
1. Test /req add with a sample requirement
2. Test /req-to-issue to create GitHub issue
3. Verify REQUIREMENTS.md is updated with issue link

## Related Documents
- CLAUDE.md - Project-specific instructions
- dot_claude/commands/req.md - Requirements command (now fixed)
- CLAUDE_COMMANDS_LOG.md - Session history