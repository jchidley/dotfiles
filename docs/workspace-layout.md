# Workspace ownership

This document records machine-wide location ownership. Project-specific truth remains in each repository.

| Location | Role |
|---|---|
| `~/git/` | Substantial version-controlled projects and deliberate upstream checkouts |
| `~/tools/` | Small maintained first-party utilities in the tools umbrella repository |
| `~/.local/bin/` | Installed user command interface |
| Windows `~/git/dotfiles/` | Canonical Windows dotfiles checkout and configured chezmoi source |
| Debian4 `~/.local/share/chezmoi/` | Canonical Linux dotfiles/bootstrap checkout on ext4; `~/git/dotfiles` resolves here |
| `~/git/ak/` | Credential utility source, metadata, and ignored encrypted runtime payload |
| `~/work/` | Disposable inspections, generated inventories, staging, and rollback bundles |
| `~/git/mkdocs-material-test/` | Personal technical knowledge garden and historical/thematic writing |

Home-relative paths resolve in the operating system running chezmoi: Debian4's `~/git/dotfiles` is not the Windows checkout. Keep the active checkouts synchronized through Git without moving Linux work onto Windows storage.

The managed `dot_config/chezmoi/chezmoi.toml` is Windows-only (`.chezmoiignore` excludes it on Linux). Windows's deployed configuration selects `~/git/dotfiles`; Debian4 uses chezmoi's default ext4 source. No blanket apply is required to synchronize Git.

Chezmoi 2.69.4's `doctor` reports that managed config as a suspicious entry because its filename is `chezmoi.toml`, not because it interprets `sourceDir` as incorrect. Verified against upstream [`IsSuspiciousSourceDirEntry` and `knownTargetFiles`](https://github.com/twpayne/chezmoi/blob/v2.69.4/internal/chezmoi/chezmoi.go) and the [doctor walker](https://github.com/twpayne/chezmoi/blob/v2.69.4/internal/cmd/doctorcmd.go). This is an understood warning for intentionally managing the Windows config; do not suppress it by reverting the correct source selection.

The older Windows `~/.local/share/chezmoi/` checkout is not the active source. Review on 9 September 2026 found its HEAD was an ancestor of the canonical checkout and all ten modified/untracked files matched canonical files byte-for-byte. Preserve it until a separately approved retirement; do not select it by removing Windows's deployed `sourceDir` setting.

## Explicit location exceptions

These are retained in place because a cosmetic move is not worth breaking deployments, services, large data/build trees, or established references:

- `~/projects/heatpump-analysis/`: active operational heat-pump project with deployment paths, submodules, data, and large build output. Reassess only as a dedicated migration.
- `~/boat-data-platform/`: active boat data platform; retain until service and path references are audited.
- `~/src/celnav/`: substantial source/build tree; retain until references and large generated content are separated.
- `~/research/`: small clean Git research checkout; its destination remains an ownership decision rather than an automatic move.
- `~/src/boat-study/` and `~/boat-data-staging/`: non-Git study/staging data. They are not authoritative source projects; classify individual contents before moving or deleting them.

`~/work/workspace-inventory.tsv` is generated evidence, not canonical configuration. Repository cloning is controlled by `scripts/bootstrap/workspace-repos.tsv`.
