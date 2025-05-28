# PROJECT_MAP.md - Active Project Directory Guide

This file maps key project directories and their purposes for quick navigation.

## Development Hub
- `/home/jack/tools` - **PRIMARY DEVELOPMENT LOCATION**
  - Central hub for all development work
  - Contains comprehensive development standards in CLAUDE.md
  - Houses general-purpose tools and scripts

## Active Projects

### System Configuration
- `~/.local/share/chezmoi` - Dotfiles management via chezmoi
  - Declarative configuration for Debian and Windows
  - Uses Go templates for conditional logic
  - Special handling: retains its own detailed CLAUDE.md

### Application Projects
- `/home/jack/garmin` - Garmin device apps and data tools
- `/home/jack/browser_tools` - Browser automation and utilities
- `/home/jack/mkdocs-material-test` - Documentation site testing

### Other Locations
- `/home/jack/src` - External source code (e.g., helix editor)
- `~/.claude` - Global Claude configuration
  - `commands/` - Custom slash commands
  - `CLAUDE.md` - Core interaction rules only

## Quick Navigation
```bash
cd /home/jack/tools           # For development work
cd ~/.local/share/chezmoi     # For config management
cd /home/jack/garmin          # For Garmin projects
```

## Adding New Projects
1. Create project directory
2. Add project-specific CLAUDE.md with:
   - Project purpose and context
   - Essential commands
   - "For general development standards, see `/home/jack/tools/CLAUDE.md`"