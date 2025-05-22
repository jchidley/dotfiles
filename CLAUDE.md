# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Type and Purpose

This is a **chezmoi-managed dotfiles repository** - a declarative configuration management system for personal development environments. The repository manages configuration files across Windows and Debian Linux systems using Go templates for conditional logic.

## Essential Commands for Development

### Chezmoi Workflow
```bash
# ALWAYS test before applying changes
chezmoi diff                    # See what would change
chezmoi apply --dry-run        # Simulate application
chezmoi apply -v               # Apply with verbose output

# Edit managed files (never edit target files directly)
chezmoi edit ~/.bashrc         # Edit source, not target
chezmoi add ~/.newconfig       # Add file to management

# Template testing
chezmoi execute-template       # Re-run templates after data changes
```

### Git Operations
```bash
# Work in source directory for git operations
chezmoi cd                     # Enter ~/.local/share/chezmoi
git status && git add -A && git commit -m "description"
```

**CRITICAL**: Never edit files in their target locations (like `~/.bashrc`). Always use `chezmoi edit` to modify the source files in the chezmoi directory.

## Chezmoi-Specific Architecture

### File Naming Conventions (chezmoi transforms these)
- `dot_filename` → `.filename` (dotfiles)
- `executable_filename` → executable file
- `filename.tmpl` → template processed with Go templates
- `private_filename` → file with 0600 permissions

### Template System
```go
// OS-specific conditionals
{{- if eq .chezmoi.os "windows" -}}
// Windows-specific content
{{- else if eq .chezmoi.osRelease.id "debian" -}}
// Debian-specific content  
{{- end -}}

// Include other files
{{- include "dot_bashrc_debian" -}}

// Template references (NOT includes)
{{- template "helix/config.toml" . -}}
```

### Critical Files and Their Purpose
- `.chezmoiignore`: Controls which files are ignored per platform
- `dot_bashrc.tmpl`: Main shell config with conditional OS sections
- `dot_bashrc_debian`: Included content for Debian systems
- Shell hint files (`bash_shell_hints`, `ps_shell_hints`): Command references

### Platform Detection in Templates
```go
{{ .chezmoi.os }}              // "windows" or "linux"
{{ .chezmoi.osRelease.id }}    // "debian", "ubuntu", etc.
{{ .chezmoi.arch }}            // "amd64", "arm64", etc.
```

## Development Workflow Patterns

### When Modifying Configurations
1. **NEVER** edit target files (like `~/.bashrc`) directly
2. Use `chezmoi edit ~/.bashrc` to edit the source
3. Test with `chezmoi diff` before applying
4. Apply with `chezmoi apply -v` (verbose for debugging)

### Adding New Dotfiles
```bash
chezmoi add ~/.newconfig        # Adds to source directory
chezmoi edit ~/.newconfig       # Edit in source
```

### Template Development
- Template syntax errors will cause `chezmoi apply` to fail
- Use `chezmoi execute-template` to test template parsing
- Test on both platforms if using conditional logic

### Git Workflow
- Source directory is at `~/.local/share/chezmoi`
- Use `chezmoi cd` to enter source directory for git operations
- Commit message should describe configuration changes, not file changes

## Environment Integration Points

### Editor Integration  
- Helix (hx) configured as primary editor across all platforms
- EDITOR, VISUAL, SUDO_EDITOR all point to hx

### Shell Environment
- Cargo environment sourced early (before which commands)
- Python venv auto-activation if .venv exists
- zoxide for directory navigation
- Shared history across sessions

### Platform-Specific Package Management
- `dot_config/windows_config/winget.json`: Windows packages
- `dot_config/cargo_install.txt`: Rust tools
- Use uv/uvx for Python packages (not pip)