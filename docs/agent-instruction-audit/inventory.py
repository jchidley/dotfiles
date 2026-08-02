#!/usr/bin/env -S uv run python
"""Inventory agent-instruction surfaces under /home/jack without emitting content.

The report is metadata-only. Secret-like content is counted by category; matching
text is never written. Run from any directory:
  uv run python /home/jack/work/agent-instruction-audit/inventory.py
"""
from __future__ import annotations

import csv
import hashlib
import os
from pathlib import Path
import re
import subprocess
from typing import Iterable

HOME = Path("/home/jack")
OUT = HOME / "work/agent-instruction-audit"
OUT.mkdir(parents=True, exist_ok=True)
SELF_OUTPUTS = {OUT / "registry.tsv", OUT / "inventory-summary.tsv", OUT / "secret-scan-counts.tsv", OUT / "filename-candidates.txt"}

STARTUP_NAMES = {
    "agents.md": "startup",
    "agent.md": "startup-or-application-prompt",
    "claude.md": "startup",
    "gemini.md": "startup",
    "codex.md": "startup",
    "skill.md": "skill",
    "copilot-instructions.md": "editor-instructions",
    ".cursorrules": "editor-rules",
    ".windsurfrules": "editor-rules",
    ".clinerules": "editor-rules",
    "system.md": "system-prompt",
    "append_system.md": "system-prompt-addition",
    "hooks.json": "hooks",
} 
CONFIG_PATHS = {
    HOME / ".pi/agent/settings.json": "settings",
    HOME / ".pi/agent/settings.json.bak-20260523121905": "settings-backup",
    HOME / ".pi/agent/keybindings.json": "settings",
    HOME / ".claude/settings.json": "settings",
    HOME / ".codex/config.toml": "settings",
    HOME / ".codex/rules/default.rules": "rules",
    HOME / ".gemini/settings.json": "settings",
    HOME / ".claude/plugins/installed_plugins.json": "plugin-registry",
    HOME / ".claude/plugins/known_marketplaces.json": "plugin-registry",
}
AGENT_DIR_PARTS = {
    ".claude/rules": "rules",
    ".claude/commands": "prompt-command",
    ".claude/prompts": "prompt-template",
    ".cursor/rules": "editor-rules",
    ".github/instructions": "editor-instructions",
}
GLOBAL_SURFACE_ROOTS = {
    HOME / ".pi/agent/agents": "agent-definition",
    HOME / ".pi/agent/prompts": "prompt-template",
    HOME / ".pi/agent/extensions": "extension",
    HOME / ".claude/commands": "prompt-command",
    HOME / ".claude/prompts": "prompt-template",
}
CANONICAL_SURFACE_ROOTS = {
    HOME / "github/agent-skills/commands": "prompt-command",
    HOME / "github/agent-skills/skills/prompts": "prompt-template",
    HOME / "github/agent-skills/extensions": "extension",
    HOME / "github/agent-skills/.pi": "settings-source",
}
TEXT_SUFFIXES = {".md", ".txt", ".json", ".jsonc", ".toml", ".yaml", ".yml", ".rules", ".ts", ".js", ".mjs", ".cjs", ".sh", ".ps1"}
SKIP_CONTENT_DIRS = {"node_modules", ".git", "__pycache__", "dist", "build", "target", ".venv", "venv"}
RISK_PATTERNS = {
    "private_key_marker": re.compile(rb"-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----"),
    "generic_api_assignment": re.compile(rb"(?i)(?:api[_-]?key|token|secret|password)\s*[:=]\s*['\"]?[A-Za-z0-9_./+\-=]{12,}"),
    "sk_prefix": re.compile(rb"(?<![A-Za-z0-9])sk-[A-Za-z0-9_-]{12,}"),
    "github_token_prefix": re.compile(rb"(?<![A-Za-z0-9])(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})"),
    "credential_url": re.compile(rb"(?i)https?://[^\s/@:]+:[^\s/@]+@"),
    "destructive_command": re.compile(rb"(?im)(?:^|[;&|]\s*)(?:sudo\s+)?(?:rm\s+-rf|git\s+reset\s+--hard|git\s+clean\s+-[a-z]*f|mkfs\b|dd\s+if=)"),
    "windows_path": re.compile(rb"(?:[A-Za-z]:\\|/mnt/[a-z]/)"),
}


def walk_files(root: Path) -> Iterable[Path]:
    if not root.exists():
        return
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        dirnames[:] = [d for d in dirnames if d not in SKIP_CONTENT_DIRS]
        for name in filenames:
            p = Path(dirpath) / name
            if p.suffix.lower() in TEXT_SUFFIXES or name.lower() in STARTUP_NAMES:
                yield p


def all_startup_candidates() -> Iterable[Path]:
    for dirpath, dirnames, filenames in os.walk(HOME, followlinks=False):
        # Exact startup names are retained even in caches/vendor; only pseudo filesystems are absent under HOME.
        for name in filenames:
            low = name.lower()
            if low in STARTUP_NAMES or low.endswith(".instructions.md") or ("hook" in low and low.endswith(".json")):
                yield Path(dirpath) / name


def all_repo_surfaces() -> Iterable[tuple[Path, str]]:
    for dirpath, dirnames, filenames in os.walk(HOME, followlinks=False):
        rel = "/" + str(Path(dirpath).relative_to(HOME)).replace(os.sep, "/")
        for marker, kind in AGENT_DIR_PARTS.items():
            if rel.endswith("/" + marker) or "/" + marker + "/" in rel + "/":
                for name in filenames:
                    p = Path(dirpath) / name
                    if p.suffix.lower() in TEXT_SUFFIXES or name.startswith("."):
                        yield p, kind
        # Settings and hook declarations can inject instructions at repository scope.
        if rel.endswith("/.claude") or rel.endswith("/.cursor") or rel.endswith("/.gemini"):
            for name in filenames:
                if name.lower().startswith("settings") and Path(name).suffix.lower() in {".json", ".jsonc", ".toml"}:
                    yield Path(dirpath) / name, "settings"
        if rel.endswith("/.github"):
            for name in filenames:
                if name.lower() == "copilot-instructions.md":
                    yield Path(dirpath) / name, "editor-instructions"


def symlink_surfaces() -> Iterable[tuple[Path, str]]:
    roots = [HOME / ".pi/agent", HOME / ".claude", HOME / ".codex", HOME / ".gemini", HOME / "github/agent-state-backup"]
    for root in roots:
        if not root.exists():
            continue
        for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
            for name in list(dirnames) + filenames:
                p = Path(dirpath) / name
                if not p.is_symlink():
                    continue
                low = str(p).lower()
                if any(x in low for x in ("skill", "command", "prompt", "extension", "agents.md", "claude.md", "keybindings")):
                    yield p, "symlink-surface"


def git_root(path: Path, cache: dict[Path, str]) -> str:
    cur = path if path.is_dir() else path.parent
    visited = []
    while cur != cur.parent:
        if cur in cache:
            root = cache[cur]
            break
        visited.append(cur)
        if (cur / ".git").exists():
            root = str(cur)
            break
        cur = cur.parent
    else:
        root = ""
    for v in visited:
        cache[v] = root
    return root


def classify(path: Path, real: Path, repo: str) -> tuple[str, str]:
    s = str(path)
    r = str(real)
    if s.startswith(str(OUT) + "/"):
        return "audit-output", "generated"
    if "/.claude/plugins/marketplaces/" in s:
        return "external", "installed-plugin-source"
    if "/.claude/plugins/cache/" in s or "/.codex/skills/.system/" in s:
        return "external", "active-installed-resource"
    if "/node_modules/" in s or "/deps/" in s or "/vendor/" in s or "/.cargo/registry/" in s or "/.vscode-server/" in s or "/unpacked/" in s:
        return "external", "vendor/dependency"
    if s.startswith(str(HOME / ".cache")) or "/.cache/" in s or "/.codex/.tmp/" in s or "/.npm/" in s:
        return "external", "cache/generated"
    if s.startswith(str(HOME / "tmp")) or s.startswith(str(HOME / "work")):
        return "mixed", "temporary/disposable"
    if s.startswith(str(HOME / "github/agent-state-backup")) or "backup" in path.name.lower() or ".bak-" in path.name.lower() or "/backups/" in s:
        return "first-party", "backup/archive"
    if s.startswith(str(HOME / ".local/share/fnm")) or s.startswith(str(HOME / ".local/share/uv")):
        return "external", "installed-package"
    if r.startswith(str(HOME / "github/agent-skills")):
        return "first-party", "maintained"
    if s.startswith(str(HOME / ".pi/agent")) or s.startswith(str(HOME / ".claude")) or s.startswith(str(HOME / ".codex")) or s.startswith(str(HOME / ".gemini")) or s == str(HOME / "CLAUDE.md"):
        return "first-party", "active-global"
    if "/_inspect/" in s or "/archive/" in s:
        return "mixed", "inspection/archive"
    if repo:
        try:
            urls = subprocess.run(["git", "-C", repo, "remote", "get-url", "--all", "origin"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False).stdout.decode("utf-8", "replace").splitlines()
            is_first_party = any(re.search(r"(?:github\.com[/:])jchidley/", re.sub(r"https?://[^/@]+@", "https://", u), re.I) for u in urls)
        except OSError:
            is_first_party = False
        if is_first_party:
            return "first-party", "repository-first-party"
        return "external", "repository-external-or-upstream"
    return "unknown", "unowned"


def activation(path: Path, real: Path, kind: str, cls: str) -> tuple[str, str, str]:
    s = str(path)
    if cls == "active-installed-resource":
        return "externally-maintained-active", "global agent installed/system resource discovery", "global agent configuration"
    if cls == "installed-plugin-source":
        return "conditional-external", "Claude plugin registry when plugin is enabled", "global Claude plugin configuration"
    if cls in {"vendor/dependency", "cache/generated", "installed-package", "backup/archive", "temporary/disposable", "inspection/archive", "repository-external-or-upstream"}:
        return "inactive-by-location", "none unless explicitly opened/entered", "contained location"
    if kind == "skill":
        if str(real).startswith(str(HOME / "github/agent-skills")):
            return "potentially-active", "Pi/Claude/Codex skill discovery through global symlinks", "global; loaded on trigger"
        return "conditional", "agent skill discovery if containing skill root is configured", "containing agent/workspace"
    if kind == "symlink-surface":
        return "active-link", "configured global symlink", "global agent configuration"
    if s == str(HOME / "CLAUDE.md"):
        return "active-for-claude", "Claude Code ancestor startup context", str(HOME)
    if s == str(HOME / ".pi/agent/AGENTS.md"):
        return "active-for-pi", "Pi global AGENTS.md", "all Pi sessions"
    if s == str(HOME / ".codex/AGENTS.md"):
        return "active-for-codex", "Codex global fallback instructions", "all Codex sessions"
    if kind in {"settings", "rules", "settings-source"}:
        return "potentially-active", "tool configuration/rules loader", "global or containing workspace"
    if kind in {"extension", "agent-definition", "prompt-template", "prompt-command"}:
        return "potentially-active", "tool resource discovery/configuration", "global or explicit invocation"
    if path.name.lower() in {"agents.md", "claude.md", "gemini.md", "codex.md", "copilot-instructions.md"}:
        return "potentially-active", "tool-specific startup/ancestor/workspace discovery", str(path.parent)
    return "conditional", "consumer-specific", str(path.parent)


def decision_for(owner: str, cls: str, active: str, kind: str) -> tuple[str, str]:
    if cls in {"vendor/dependency", "installed-package", "active-installed-resource", "installed-plugin-source", "repository-external-or-upstream"}:
        return "leave-external-unchanged; manage activation via tool/workspace configuration", "package/vendor/upstream owner"
    if cls == "cache/generated":
        return "leave-generated-unchanged; remove only via owning cache lifecycle", "cache owner"
    if cls in {"backup/archive", "inspection/archive", "temporary/disposable"}:
        return "keep-out-of-active-discovery; remove/archive only in workspace cleanup after uniqueness check", "workspace cleanup"
    if kind == "symlink-surface":
        return "retain link only if canonical target remains approved; eliminate broken/duplicate links", str(Path(os.path.realpath(str(HOME / "github/agent-skills"))))
    if owner == "first-party" and active not in {"inactive-by-location"}:
        return "review/reconcile in prioritized safe edit plan; no edit in this audit", "nearest reviewed AGENTS.md or canonical agent-skills source"
    return "classify repository ownership and activation before edit; leave unchanged meanwhile", "owner repository"


def summary_from(data: bytes, kind: str) -> str:
    # Only low-risk structural metadata, never arbitrary lines or values.
    text = data.decode("utf-8", "replace")
    if kind == "skill":
        m = re.search(r"(?m)^name:\s*['\"]?([A-Za-z0-9_.-]+)", text[:5000])
        return "skill playbook" + (f" ({m.group(1)})" if m else "")
    headings = re.findall(r"(?m)^#{1,2}\s+([^\r\n]{1,100})", text)
    safe_heads = []
    for h in headings[:3]:
        h = re.sub(r"[`\[\]{}<>]", "", h).strip()
        if re.fullmatch(r"[A-Za-z0-9 ._:/()&+-]{1,100}", h):
            safe_heads.append(h)
    return f"{kind}; sections: " + ", ".join(safe_heads) if safe_heads else kind


def main() -> None:
    found: dict[Path, str] = {}
    for p in all_startup_candidates():
        low = p.name.lower()
        if low in STARTUP_NAMES:
            found[p] = STARTUP_NAMES[low]
        elif low.endswith(".instructions.md"):
            found[p] = "editor-path-instructions"
        else:
            found[p] = "hooks"
    for p, kind in all_repo_surfaces():
        found.setdefault(p, kind)
    for p, kind in CONFIG_PATHS.items():
        if p.exists() or p.is_symlink():
            found.setdefault(p, kind)
    for root, kind in {**GLOBAL_SURFACE_ROOTS, **CANONICAL_SURFACE_ROOTS}.items():
        for p in walk_files(root) or []:
            found.setdefault(p, kind)
    for p, kind in symlink_surfaces():
        found.setdefault(p, kind)

    repo_cache: dict[Path, str] = {}
    rows = []
    risk_totals = {k: 0 for k in RISK_PATTERNS}
    for path in sorted(found, key=lambda p: str(p)):
        if path in SELF_OUTPUTS:
            continue
        try:
            real = path.resolve(strict=True)
            if path.is_symlink() and real.is_dir():
                data = b""
                size = 0
                lines = 0
                digest = hashlib.sha256(("symlink->" + str(real)).encode()).hexdigest()
            else:
                data = real.read_bytes()
                size = len(data)
                lines = data.count(b"\n") + (1 if data and not data.endswith(b"\n") else 0)
                digest = hashlib.sha256(data).hexdigest()
        except (OSError, RuntimeError):
            real = Path(os.path.realpath(path))
            data = b""
            size = 0
            lines = 0
            digest = "unreadable-or-broken"
        repo = git_root(real, repo_cache)
        owner, cls = classify(path, real, repo)
        active, mechanism, scope = activation(path, real, found[path], cls)
        decision, destination = decision_for(owner, cls, active, found[path])
        risks = []
        for name, regex in RISK_PATTERNS.items():
            count = len(regex.findall(data))
            risk_totals[name] += count
            if count:
                risks.append(f"{name}:{count}")
        if path.is_symlink():
            risks.append("symlink")
        apparent_age = "mtime=" + __import__("datetime").datetime.fromtimestamp(path.lstat().st_mtime, __import__("datetime").timezone.utc).date().isoformat()
        stable_id = "AI-" + hashlib.sha256(str(path).encode()).hexdigest()[:12]
        duplicate_key = digest if digest != "unreadable-or-broken" else ""
        rows.append({
            "stable_id": stable_id,
            "path": str(path),
            "real_path": str(real),
            "type": found[path],
            "bytes": size,
            "lines": lines,
            "sha256": digest,
            "owning_repository": repo,
            "ownership": owner,
            "classification": cls,
            "consumer": mechanism.split()[0] if mechanism else "unknown",
            "discovery_mechanism": mechanism,
            "scope": scope,
            "current_activation": active,
            "content_summary": summary_from(data, found[path]),
            "unique_information": "manual review required" if owner in {"first-party", "unknown"} and cls not in {"backup/archive", "temporary/disposable"} else "not assessed; non-authoritative copy",
            "duplication": "group by sha256=" + duplicate_key[:12] if duplicate_key else "none established",
            "apparent_age": apparent_age,
            "verification": "complete-byte read; metadata/hash; activation requires discovery evidence",
            "risks_count_only": ",".join(risks) if risks else "none detected by limited patterns",
            "decision": decision,
            "destination_or_archive": destination,
            "validation": "re-run inventory.py; tool-specific discovery test before edit",
            "commit": "not-applicable-read-only-audit",
            "review_date": "2026-08-03",
        })

    fields = list(rows[0]) if rows else []
    with (OUT / "registry.tsv").open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields, delimiter="\t", lineterminator="\n")
        w.writeheader(); w.writerows(rows)
    with (OUT / "secret-scan-counts.tsv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["pattern_category", "match_count"])
        w.writerows(sorted(risk_totals.items()))
    counters: dict[tuple[str, str], int] = {}
    for row in rows:
        k = (row["type"], row["classification"])
        counters[k] = counters.get(k, 0) + 1
    with (OUT / "inventory-summary.tsv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["type", "classification", "count"])
        for (kind, cls), count in sorted(counters.items()):
            w.writerow([kind, cls, count])
    print(f"Wrote {len(rows)} metadata-only registry rows to {OUT / 'registry.tsv'}")
    print(f"Count-only risk categories written to {OUT / 'secret-scan-counts.tsv'}")

if __name__ == "__main__":
    main()
