# Project: Chezmoi Dotfiles
Updated: 2025-01-09 17:52

## Current State
Status: Claude Code hooks implemented and documentation consolidated
Target: Clean, minimal dotfiles configuration with robust scripting standards
Latest: Consolidated Claude Code hooks documentation, removing 5 outdated files

## Essential Context
- Removed 13 unused commands following minimal philosophy
- Claude Code's built-in planning and todo features replace custom implementations
- HANDOFF.md todo persistence still necessary for cross-session continuity
- All CLAUDE.md files updated to reflect native Claude Code features
- New /standards command checks project compliance with all standards
- Windows Terminal commands now properly echo as hints in PowerShell
- Wisdom capture patterns centralized in wisdom-triggers.md (DRY principle)
- New commands: /clean-wisdom (pattern distillation), /wisdom (pattern application)
- /checkpoint now creates minimal CHECKPOINT.md safety net
- /wrap-session writes checkpoint first for resilience to context limits
- Claude Code hooks now enforce formatting/linting automatically (tools/claude-hooks/)
- tools/CLAUDE.md updated to focus on philosophy while hooks handle mechanics

## Next Step
Commit the Claude Code hooks implementation and updated documentation

## Active Todo List
All tasks completed

## If Blocked
None - system fully operational

## Related Documents
- CLAUDE.md - Project instructions
- PROJECT_WISDOM.md - Development insights
- SESSION_MANAGEMENT_WORKFLOW.md - How sessions work
- WORKING_WITH_CLAUDE.md - Human-AI collaboration guide
- sessions/ - Archive directory with historical logs