# Workspace ownership

This document records machine-wide location ownership. Project-specific truth remains in each repository.

| Location | Role |
|---|---|
| `~/github/` | Substantial version-controlled projects and deliberate upstream checkouts |
| `~/tools/` | Small maintained first-party utilities in the tools umbrella repository |
| `~/.local/bin/` | Installed user command interface |
| `~/.local/share/chezmoi/` | Sole authoritative dotfiles and machine-bootstrap checkout |
| `~/github/ak/` | Credential utility source, metadata, and ignored encrypted runtime payload |
| `~/work/` | Disposable inspections, generated inventories, staging, and rollback bundles |
| `~/github/mkdocs-material-test/` | Personal technical knowledge garden and historical/thematic writing |

## Explicit location exceptions

These are retained in place because a cosmetic move is not worth breaking deployments, services, large data/build trees, or established references:

- `~/projects/heatpump-analysis/`: active operational heat-pump project with deployment paths, submodules, data, and large build output. Reassess only as a dedicated migration.
- `~/boat-data-platform/`: active boat data platform; retain until service and path references are audited.
- `~/src/celnav/`: substantial source/build tree; retain until references and large generated content are separated.
- `~/research/`: small clean Git research checkout; its destination remains an ownership decision rather than an automatic move.
- `~/src/boat-study/` and `~/boat-data-staging/`: non-Git study/staging data. They are not authoritative source projects; classify individual contents before moving or deleting them.

`~/work/workspace-inventory.tsv` is generated evidence, not canonical configuration. Repository cloning is controlled by `scripts/bootstrap/workspace-repos.tsv`.
