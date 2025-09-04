# Personal Dotfiles

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/) for consistent development environments across Windows and Debian Linux systems.

## Quick Start

### New Machine Setup

```bash
# Install chezmoi and apply dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/your-username/dotfiles.git
```

### Update Existing Installation

```bash
# Pull latest changes and apply
chezmoi update
```

## Features

- **Cross-platform support**: Windows (PowerShell) and Debian Linux (Bash)
- **Conditional configuration**: OS-specific settings using chezmoi templates
- **Development tools integration**: Neovim, Rust, Python (uv/uvx), Git
- **Shell enhancements**: zoxide navigation, ripgrep search, shared history
- **Package management**: Automated tool installation configs

## Supported Platforms

- **Windows**: PowerShell profile, Windows Terminal settings, winget packages
- **Debian Linux**: Bash configuration, APT packages, development tools

## Key Tools Configured

- **Editor**: [Neovim](https://neovim.io/) as primary editor
- **Shell**: Enhanced Bash/PowerShell with custom prompts and aliases
- **Python**: [uv](https://github.com/astral-sh/uv) for package management
- **Rust**: Cargo environment and development tools
- **Search**: ripgrep with custom configuration
- **Navigation**: zoxide for smart directory jumping
- **Terminal**: Windows Terminal with custom settings

## Daily Workflow

### Making Changes

```bash
# Edit a dotfile
chezmoi edit ~/.bashrc

# Preview changes
chezmoi diff

# Apply changes
chezmoi apply -v
```

### Managing Files

```bash
# Add new dotfile to management
chezmoi add ~/.newconfig

# Remove file from management
chezmoi remove ~/.oldconfig

# Enter source directory for git operations
chezmoi cd
```

### Git Operations

```bash
# Enter chezmoi source directory
chezmoi cd

# Commit and push changes
git add -A
git commit -m "Update configuration"
git push
```

## Structure

```
~/.local/share/chezmoi/
├── dot_bashrc.tmpl              # Main bash configuration
├── dot_bashrc_debian            # Debian-specific bash config
├── dot_gitconfig.tmpl           # Git configuration
├── dot_ripgreprc                # ripgrep configuration
├── .chezmoiignore               # Platform-specific ignore rules
├── AppData/                     # Windows-specific files
│   ├── Roaming/helix/
│   └── Local/Packages/Microsoft.WindowsTerminal_*/
├── Documents/PowerShell/        # PowerShell profile
├── dot_config/                  # Unix configuration files
│   ├── helix/
│   └── windows_config/          # Windows package configs
├── bash_shell_hints             # Linux command reference
└── ps_shell_hints               # Windows command reference
```

## Platform-Specific Features

### Windows
- PowerShell profile with custom prompt
- Windows Terminal configuration
- winget package management
- Python path detection and setup
- SSH agent configuration

### Linux (Debian)
- Enhanced bash configuration
- Neovim editor integration  
- Cargo/Rust development environment
- Python virtual environment auto-activation
- SSH key management

## Requirements

### Base Requirements
- [chezmoi](https://www.chezmoi.io/)
- Git

### Platform-Specific
**Windows:**
- PowerShell 7+
- [Windows Terminal](https://github.com/microsoft/terminal)
- [winget](https://github.com/microsoft/winget-cli)

**Linux:**
- Bash 4.0+
- curl

### Development Tools (auto-configured)
- [Neovim](https://neovim.io/)
- [Rust/Cargo](https://rustup.rs/)
- [uv](https://github.com/astral-sh/uv) (Python)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fzf](https://github.com/junegunn/fzf)

## Customization

### Adding New Configurations

1. Add file to chezmoi management:
   ```bash
   chezmoi add ~/.newconfig
   ```

2. Edit if needed:
   ```bash
   chezmoi edit ~/.newconfig
   ```

3. For platform-specific configs, use templates:
   ```bash
   chezmoi edit ~/.newconfig.tmpl
   ```

### Template Variables

Access OS information in templates:
- `{{ .chezmoi.os }}` - Operating system (windows/linux)
- `{{ .chezmoi.osRelease.id }}` - OS distribution (debian/ubuntu/etc.)

### Package Management

- **Windows**: Edit `dot_config/windows_config/winget.json`
- **Rust**: Edit `dot_config/cargo_install.txt`

## Troubleshooting

### Check Status
```bash
# See what would change
chezmoi diff

# Verify chezmoi state
chezmoi verify

# Check for issues
chezmoi doctor
```

### Reset Configuration
```bash
# Re-apply all configurations
chezmoi apply --force
```

## Contributing

1. Make changes using `chezmoi edit`
2. Test with `chezmoi diff` and `chezmoi apply --dry-run`
3. Apply changes with `chezmoi apply`
4. Commit and push from `chezmoi cd`
