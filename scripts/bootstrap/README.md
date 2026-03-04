# Debian Bootstrap Scripts

Saved bootstrap variants for rebuilding from scratch.

## Scripts

1. `debian-bootstrap-legacy.sh`
   - Your original workflow, preserved as-is for reference.

2. `debian-bootstrap-safe.sh`
   - Improved, rerunnable, safer auth handling, paginated repo cloning.

## Suggested order

- Use `debian-bootstrap-safe.sh` as the default.
- Keep `debian-bootstrap-legacy.sh` only as a fallback/reference.

## Run

```bash
cd ~/github/dotfiles/scripts/bootstrap

# Minimal startup set (whitelist only)
BOOTSTRAP_MODE=core ./debian-bootstrap-safe.sh

# Full sync (all repos except blacklist)
BOOTSTRAP_MODE=full ./debian-bootstrap-safe.sh
```

## Repo selection modes

- `BOOTSTRAP_MODE=core`
  - Clones whitelist only (`WHITELIST_REPOS`)
  - Default whitelist: `dotfiles,ak,agent-skills,tools`

- `BOOTSTRAP_MODE=full`
  - Clones all repos except `EXCLUDE_REPOS`
