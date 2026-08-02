# Agent-instruction surface audit

**Scope:** `/home/jack`  
**Mode:** read-only evidence audit; no source/configuration/Git repository edits  
**Review date:** 2026-08-03

## Executive result

The reproducible inventory records **1,016 candidate surfaces** in `registry.tsv`. Every row has a stable ID, path and real path, type, byte/line counts, SHA-256, repository ownership metadata, activation proposal, scope, count-only risk flags, and a decision. The inventory includes startup files, settings, rules, hooks, extensions, skills, prompt templates, symlinks, vendor/dependency material, caches, backups, archives, generated copies, and temporary checkouts.

This was time-boxed before the planned semantic reviewer passes finished. The registry is therefore a **registry proposal and safe edit plan**, not a claim that 282 potentially active first-party rows have all received line-by-line human adjudication. Every regular candidate was completely byte-read for hashing/count-only checks; active first-party content still marked `review/reconcile` must receive the per-file semantic protocol before edits.

## Deliverables

| File | Purpose |
|---|---|
| `inventory.py` | Reproducible metadata-only inventory and count-only risk scan |
| `registry.tsv` | 1,016-row registry proposal |
| `inventory-summary.tsv` | Counts by type/classification |
| `secret-scan-counts.tsv` | Aggregate pattern counts only; no matched text |
| `repo_state.py` / `repository-state.tsv` | Git root, branch, head, dirty counts, remote host/owner and credential-bearing-remote count; URLs and changed paths omitted |
| `pi-discovery-test.sh` / `pi-discovery-runtime.txt` | Repeatable Pi startup discovery test from representative directories |
| `filename-candidates.txt` | Exact conventional filename discovery set (679 files at initial scan) |
| `additional-candidates.txt` | Explicit system-prompt/hook/path-instruction discovery evidence |
| `VERIFY.md` | Integrity and coverage checks |

## Inventory findings

### Ownership and containment

| Classification | Rows | Default decision |
|---|---:|---|
| Cache/generated | 294 | Leave unchanged; remove only through owning cache lifecycle |
| Temporary/disposable | 201 | Keep outside active discovery; uniqueness check before cleanup |
| Maintained canonical surfaces | 170 | Review/reconcile in canonical first-party scope |
| Backup/archive | 107 | Keep outside discovery; treat agent-state backup as sensitive |
| First-party repository surfaces | 96 | Repository-by-repository semantic review before edit |
| Vendor/dependency | 47 | Leave upstream unchanged |
| External/upstream repositories | 41 | Leave unchanged; manage only activation/workspace placement |
| Installed plugin source | 31 | Leave external source unchanged; enable only deliberately |
| Active global | 16 | Highest-priority reconciliation scope |
| Inspection/archive | 6 | Keep outside active discovery |
| Active installed resources | 5 | External; manage activation, not source |
| Installed package | 2 | Leave unchanged |

There are **113 exact-duplicate hash groups covering 389 rows**. Most duplication is explained by global skill/command symlinks, backups, caches, and temporary checkouts. Hash grouping does not authorize deletion.

### Activation

- 698 rows are inactive by contained location.
- 143 are potentially active through startup/resource discovery.
- 85 are active symlink surfaces pointing chiefly to `~/github/agent-skills`.
- Pi, Codex, and Claude each have one explicitly active global startup file in the registry.
- Five system/installed agent resources are active but externally maintained.
- **282 first-party rows are active or potentially active** and remain the semantic-review queue.

### Count-only safety scan

Aggregate matches across candidate content:

- credential-bearing URL pattern: 2 matches in 1 row;
- GitHub-token prefix pattern: 1 match in 1 row;
- generic key/token/password assignment pattern: 37 matches in 22 rows;
- private-key marker: 0;
- `sk-`-style pattern: 0;
- destructive-command pattern: 3 matches in 3 rows;
- Windows/`/mnt` path pattern: 147 matches in 32 rows.

These are triage signals, not proof that each match is a live credential or unsafe command. No matching value was printed or copied. The credential-pattern rows require private remediation before publication; preserve the handoff's special containment rules for `agent-state-backup`.

## Verified discovery behavior

### Pi 0.83.0

Installed documentation and runtime startup captures agree:

- global context: `~/.pi/agent/AGENTS.md`;
- ancestor traversal from home toward the working directory;
- within a directory, `AGENTS.md` is preferred and `CLAUDE.md` is the fallback (both are not loaded at the same directory when `AGENTS.md` exists);
- context files are concatenated from global/ancestors/current scope;
- global skills: `~/.pi/agent/skills` and `~/.agents/skills`; project skills additionally use `.pi/skills` and `.agents/skills` subject to project trust;
- global prompts: `~/.pi/agent/prompts/*.md` (non-recursive); project prompts require trust;
- global extensions: `~/.pi/agent/extensions/*.ts` and `*/index.ts`; project extensions require trust;
- project `.pi/settings.json` overrides global settings after trust;
- `SYSTEM.md` replaces and `APPEND_SYSTEM.md` appends to the system prompt when present.

Representative runtime captures show:

- from `/home/jack`: `.pi/agent/AGENTS.md` plus `~/CLAUDE.md`;
- from maintained repositories with both root `AGENTS.md` and `CLAUDE.md`: global Pi instructions, home `CLAUDE.md`, and repository `AGENTS.md`; the same-directory `CLAUDE.md` is not also listed;
- 30 canonical first-party skills, three prompt templates, and ten extension entries are globally active through links/configuration.

This confirms a real global overlap: Pi currently receives both `~/.pi/agent/AGENTS.md` and `~/CLAUDE.md` in all tested project sessions.

### Claude Code 2.1.112

Official documentation evidence establishes hierarchical `CLAUDE.md`, `.claude/rules/*.md`, user/project/local settings, skills, commands, plugins and hooks. Current settings enable one external LSP plugin and suppress the dangerous-mode warning. Global command/prompt/skill links point to `~/github/agent-skills`. No secret-bearing auth/history files were inventoried as instruction content.

Exact effective memory output was not invoked because that would require an interactive/model session. Treat Claude hierarchy precedence as documented evidence and validate with `/memory`/`InstructionsLoaded` hooks immediately before edits.

### Codex CLI 0.124.0

Official OpenAI documentation establishes a global chain from `CODEX_HOME` (`AGENTS.override.md` before `AGENTS.md`) followed by one instruction file per directory from project root to cwd, with nearer scopes later in the chain. Current global surface is `~/.codex/AGENTS.md`; `~/.codex/rules/default.rules` and system skills are separate active resources. External `.codex/.tmp/plugins` content is cache/generated and must not be edited.

### Gemini

The Gemini executable is not installed. Existing `~/.gemini/settings.json` sets `contextFileName` to `AGENTS.md`, so future Gemini CLI installation would use `AGENTS.md` rather than the default `GEMINI.md`. Official Gemini CLI documentation describes hierarchical memory from global/project/ancestor scopes. Activation is therefore configured-but-not-currently-executable.

### GitHub Copilot/editor integrations

Repository-wide `.github/copilot-instructions.md` and path-specific `.github/instructions/*.instructions.md` candidates are inventoried. GitHub documentation does not define a universal precedence among every custom-instruction class, so the registry deliberately does not invent one. Most path-specific candidates are in temporary/external checkouts and should remain unchanged.

## Conflicts and stale-risk priorities

1. **Global overlap:** Pi loads both `~/.pi/agent/AGENTS.md` and `~/CLAUDE.md`; content duplication/conflict should be removed by making one machine-wide authority and retaining only a compatibility pointer where verified useful.
2. **Three global authorities:** Pi, Codex and home Claude surfaces can drift independently. Reconcile machine-wide WSL, secrets, and screenshot rules into one managed vendor-neutral source, then generate/pointer tool-specific compatibility surfaces.
3. **Repository dual files:** maintained repositories commonly contain both `AGENTS.md` and substantive `CLAUDE.md`. Pi currently ignores same-directory Claude content when AGENTS exists, while Claude may load it. Preserve unique content before making Claude pointer-only.
4. **Skill fan-out:** 85 active links expose canonical skills/commands/extensions to multiple agents. Canonical edits belong in `~/github/agent-skills`; do not edit linked copies.
5. **Generated/external masquerade risk:** 294 cache/generated and 47 vendor rows include plausible startup filenames. They are inactive by placement unless an agent is launched inside those trees; do not modernize them.
6. **Backups:** 107 backup/archive rows include agent-state material. They are non-authoritative and potentially sensitive; keep private and outside discovery.
7. **Stale paths/platform assumptions:** 32 files contain Windows or `/mnt` path patterns. The known MkDocs `CLAUDE.md` stale Windows checkout and direct tool commands should be verified against UV before any rewrite.
8. **Unsafe examples:** three destructive-command matches require contextual review; examples may be legitimate warnings, but no retained instruction should normalize destructive defaults.

## Prioritized safe edit plan

No edits were made in this audit. Execute later as coherent repository batches:

1. **Credential containment first**
   - Privately inspect the two credential-URL matches and one GitHub-token-prefix match.
   - Remove live values from active guidance/remotes/backups without displaying them.
   - Keep service names only and route durable retrieval through `ak`.

2. **Global stack**
   - Reconcile `~/CLAUDE.md`, `~/.pi/agent/AGENTS.md`, `~/.codex/AGENTS.md`, Gemini's configured context filename, and chezmoi sources.
   - Preserve only machine-wide boundaries/gotchas; remove project facts.
   - Validate Pi startup capture, Claude `/memory`, Codex startup chain, and Gemini only if installed.

3. **Canonical agent-skills repository**
   - Review each canonical `SKILL.md`, command, prompt and prompt-injecting extension in full.
   - Resolve trigger overlap, scriptify fragile prose, validate scripts/tests, then confirm every global symlink target and no duplicate extension registration.

4. **Foundation repositories**
   - `ak`, chezmoi, `agent-skills`, `tools`, `lat.md`, MkDocs, workspace/bootstrap tooling, and sensitive backup infrastructure.
   - Preserve all pre-existing dirty states recorded in `repository-state.tsv`.

5. **Active operational projects**
   - Start with `heatpump-analysis`, `boat-data-platform`, `energy-hub`, `z2m-hub`, and other actively deployed first-party scopes.
   - Root before nested scope; verify commands against manifests/runtime; archive substantive unique retired guidance.

6. **Dormant first-party work**
   - Prefer archive/history decisions over cosmetic modernization.

7. **External/generated/disposable**
   - Leave upstream/vendor/cache source unchanged.
   - Remove temporary copies only under workspace cleanup after unique-work and dirty-tree checks.

8. **Final conflict audit**
   - Re-run inventory, count-only credential checks, effective discovery tests, link checks, project tests and Git-status comparison.

## Git/worktree preservation

`repository-state.tsv` covers 68 Git roots and omits remote URLs and changed paths. It records dirty repositories, including the sensitive backup and multiple first-party projects. No checkout was reset, cleaned, committed, moved, or edited by this audit. During the final recheck, the MkDocs head changed concurrently from `c0dab9ddcbd6` to `68c46671d46e`; this metadata-only drift is recorded in `repository-state-drift.md`. The MkDocs untracked `tools/` material was not touched by this audit.

## Decision rule

The row-level decision in `registry.tsv` is authoritative for this audit stage:

- **review/reconcile** means semantic review before any edit;
- **retain link conditionally** means edit only the canonical target;
- **leave external unchanged** means control activation/location, not upstream content;
- **keep out of discovery** means archive/cleanup only after uniqueness checks;
- **leave generated unchanged** means use the owning cache/package lifecycle.
