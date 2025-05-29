# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Repository Type

**chezmoi-managed dotfiles repository** - Manages configuration files across Windows and Linux systems using Go templates.

## Critical Rules

1. **NEVER edit target files directly** (e.g., `~/.bashrc`)
   - Always use `chezmoi edit ~/.bashrc` to modify source files
   - Test with `chezmoi diff` before applying changes
   
2. **File naming conventions** (chezmoi transforms these):
   - `dot_filename` → `.filename`
   - `executable_filename` → executable file
   - `filename.tmpl` → Go template
   - `private_filename` → 0600 permissions

3. **Source directory**: `~/.local/share/chezmoi/`
   - Use `chezmoi cd` to enter for git operations

## References

- **Chezmoi documentation**: https://www.chezmoi.io/
- **Development standards**: `/home/jack/tools/CLAUDE.md`