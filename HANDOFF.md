# Project: Chezmoi Dotfiles
Updated: 2025-06-02 07:26

## Current State
Status: /req commands rewritten with natural usage pattern and smart detection
Target: Clean, minimal dotfiles configuration with robust scripting standards
Latest: /req command now auto-detects relationships and creates GitHub issues

## Essential Context
- **RESOLVED**: /req commands now have detailed instructions (200+ lines vs 30)
- /req <description> is primary usage - no subcommands needed
- Automatically detects related requirements and offers to add detail
- Creates GitHub issues automatically when in GitHub repository
- Appends to existing requirements via GitHub comments or REQUIREMENTS.md
- /req-to-issue enhanced with full error handling and prerequisite checks
- Commands verified to have no overlap with other issue-tracking commands
- Checkpoint/wrap-session handle multiple checkpoints properly
- dot_claude properly transforms to ~/.claude without nested subdirectories
- Tool permissions fully automated with interactive approval UI

## Next Step
Test the new /req commands with real requirements to verify workflow

## If Blocked
None - system fully operational

## Related Documents
- CLAUDE.md - Project instructions
- SESSION_MANAGEMENT_WORKFLOW.md - How sessions work
- WORKING_WITH_CLAUDE.md - Human-AI collaboration guide
- sessions/ - Archive directory with historical logs