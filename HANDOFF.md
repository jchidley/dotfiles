# Project: Chezmoi Dotfiles
Updated: 2025-07-02 08:29

## Current State
Status: Updated Windows Terminal tab targeting configuration
Target: Clean, minimal dotfiles configuration with robust scripting standards
Latest: Changed Windows Terminal commands from `-t 0` to `-t 1` across bash and PowerShell configs

## Essential Context
- Removed 13 unused commands following minimal philosophy
- Claude Code's built-in planning and todo features replace custom implementations
- HANDOFF.md todo persistence still necessary for cross-session continuity
- All CLAUDE.md files updated to reflect native Claude Code features
- New /standards command checks project compliance with all standards

## Next Step
Apply changes with `chezmoi apply` and verify Windows Terminal behavior

## Active Todo List
[✓] Update wt.exe command in dot_bashrc.tmpl from -t 0 to -t 1
[✓] Update wt.exe command in bash_shell_hints from -t 0 to -t 1

## If Blocked
None - system fully operational

## Related Documents
- CLAUDE.md - Project instructions
- PROJECT_WISDOM.md - Development insights
- SESSION_MANAGEMENT_WORKFLOW.md - How sessions work
- WORKING_WITH_CLAUDE.md - Human-AI collaboration guide
- sessions/ - Archive directory with historical logs