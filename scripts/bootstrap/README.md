# Debian bootstrap

`debian-bootstrap-safe.sh` rebuilds the declared WSL workspace. It is repository-only code: chezmoi does not render it into `~/scripts`.

## Repository selection

`workspace-repos.tsv` is the executable inventory. Each row assigns one explicit repository to a group, destination, and profile. Bootstrap never queries GitHub for every repository.

- `foundation`: dotfiles, `ak`, agent skills, and maintained tools
- `active`: actively maintained first-party projects
- `references`: deliberate upstream or fork checkouts
- `optional`: machine- or task-specific repositories

`BOOTSTRAP_MODE=core` selects `foundation`. `BOOTSTRAP_MODE=full` selects all declared groups for the selected profile; it does **not** mean every GitHub repository.

## Run

From the authoritative chezmoi source checkout:

```bash
cd ~/.local/share/chezmoi/scripts/bootstrap
BOOTSTRAP_MODE=core BOOTSTRAP_PROFILE=dev ./debian-bootstrap-safe.sh
```

Inspect behavior without system, network, or filesystem changes:

```bash
BOOTSTRAP_DRY_RUN=1 SKIP_SYSTEM_PACKAGES=1 ./debian-bootstrap-safe.sh
```

Set `APPLY_CHEZMOI=1` only after reviewing `chezmoi diff`. The legacy one-pass bootstrap is historical evidence under `docs/archive/bootstrap/` and is not an operational fallback.
