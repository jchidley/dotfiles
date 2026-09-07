# Personal Dotfiles

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/) for consistent development environments across Windows and Debian Linux systems.

## Current Debian4 work

Follow the [Debian4 completion and selective-migration plan](docs/DEBIAN4-PLAN.md). Debian4 is the clean successor. Debian-Recovered is the authoritative known-good source and Windows default. Debian-Backup is a stopped writable clone of the protected August forensic image for controlled inspection and recovery. Both source distros are temporary: extract everything useful into Debian4, prove independent recovery, then consider their separately approved removal. Generic setup examples below are not the Debian4 execution plan.

## Quick Start

### New Debian Machine (minimal bootstrap)

Run this on a fresh Debian install:

```bash
sudo apt update && sudo apt install -y curl git
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply jchidley
```

This installs chezmoi and applies all managed dotfiles.

### Debian workspace bootstrap

After chezmoi is initialized, run the repository-only bootstrap from the authoritative source checkout:

```bash
# Foundation repositories declared in workspace-repos.tsv
BOOTSTRAP_MODE=core ~/.local/share/chezmoi/scripts/bootstrap/debian-bootstrap-safe.sh

# Every explicitly declared group for the selected profile
BOOTSTRAP_MODE=full ~/.local/share/chezmoi/scripts/bootstrap/debian-bootstrap-safe.sh
```

`full` never means every repository returned by the GitHub API.

### Update Existing Installation

```bash
# Pull latest changes and apply
chezmoi update
```

### WSL backup and recovery

For current work, start with the [Debian4 plan](docs/DEBIAN4-PLAN.md) and [build results](docs/DEBIAN4-RESULTS.md). Backup [status](scripts/wsl-backup/STATUS.md) preserves dated evidence; the retired [Debian3 recovery plan](scripts/wsl-backup/RECOVERY-PLAN.md) is only a historical pointer. Preserve Debian-Recovered, stopped Debian-Backup, the immutable August image, and relevant histories until extraction and recovery gates pass.

For an explicitly approved installation/update of the backup toolset (not a recovery-verification command):

```bash
cd ~/.local/share/chezmoi
./scripts/wsl-backup/setup.sh
wsl-backup status
```

See [`scripts/wsl-backup/README.md`](scripts/wsl-backup/README.md) for operations and safety boundaries.

## Features

- **Cross-platform support**: Windows (PowerShell 7) and Debian Linux (Bash)
- **Conditional configuration**: OS-specific settings using chezmoi templates
- **Development tools integration**: Neovim, Rust, Python (uv/uvx), Git
- **Shell enhancements**: zoxide navigation, ripgrep search, shared history
- **Package management**: Automated tool installation configs

## Supported Platforms

- **Windows**: PowerShell 7 profile, Windows Terminal settings, winget packages
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
- PowerShell 7 (`pwsh.exe`) profile with custom prompt; Windows PowerShell 5.1 is unsupported
- [Windows Terminal configuration](docs/windows-terminal.md)
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
