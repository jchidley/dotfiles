# Debian4 backup preparation and restore gates

Source-only review, 7 September 2026. This supplements [the migration plan](DEBIAN4-PLAN.md); it is not an executable runbook or approval to deploy, retrieve credentials, initialize storage, import a distro, schedule work, or retire sources.

## Selected source and proposed coverage

The source must be explicitly named **Debian4**, with home `/home/jack`. Never substitute a default/first distro or reuse a surviving system's repository. Capture a fresh bounded source inventory when preparing the actual backup; historical counts are not current deletion thresholds.

| Material | Required recovery evidence |
|---|---|
| Native Pi sessions/transcripts and the separately marked recovery archive | Preserve exact bytes, paths, permissions and provenance. Keep variants and unresolved gaps separate; do not rerun the importer. |
| McFly and Bash histories | Consistent SQLite recovery copy with an integrity check; preserve the selected merged history. |
| Git work | Preserve local commits, dirty/untracked work and selected ignored/local-only data, not just remote URLs. Record repository identity and expected recovery state. |
| Dotfiles and bootstrap source | Recover committed source plus any explicitly selected pending work; demonstrate a reproducible clean setup separately from data restoration. |
| SSH and the new AK/GPG identity | Treat as secret-bearing contents. Demonstrate recovery of the required private identity and independently supplied passphrases without exposing values in logs, arguments or transcripts. Runtime decryption alone is not independent recovery. |
| PostgreSQL/boat databases | Still an owner workflow decision. Do not require a Debian4 service or two historical dumps merely because Debian3's validator did. Preserve authoritative source data until selected recovery is settled. |

Review generated dependencies/caches separately from irreplaceable data. Do not use blanket exclusions that silently discard ignored work or recovery evidence. Preserve the independent Pi import staging and all source evidence regardless of whether a backup includes another copy.

## Missing owner prerequisites

- Select an **explicitly new** Restic repository and protected storage destination, including whether protection covers loss of the laptop. Same-disk storage does not meet laptop-loss recovery.
- Select the independently recoverable backup-password method and protection for the new private key/passphrase. Do not automate Bitwarden or regenerate an existing password.
- For a whole-distro export, approve the exact secret-bearing payload, destination, downtime, final source state, disposable import identity/location, elevation and cleanup effects.

These choices were deferred. Source review and disposable fixture tests can continue without them; real backup/restore and deployment cannot.

## Candidate findings: not accepted for execution

The preserved Windows candidate requires further implementation and behavioral tests:

1. `home/home.conf` still names `Debian-Recovered`, retains an obsolete repository landmark (`boat-data-platform/.git` directly under home), and carries historical size/count thresholds. Derive Debian4 landmarks and guards from the selected inventory rather than changing only a host label. Installation replaces this configuration and is not a read-only check.
2. The exporter defaults to `Debian-Recovered` and legacy Windows task coordination. Current operations must explicitly select Debian4 and the reviewed Linux-owned scheduling contract. Do not recreate old Windows tasks.
3. The system validator and manifest evidence still assume Debian3's two PostgreSQL dumps. Define the selected Debian4 restore result before adapting the implementation; retain historical manifest evidence without upgrading its assurance.
4. `Test-ImportedArchive` ignores native unmount/unregister exit codes in `finally`, then recursively removes the validation directory. Cleanup must verify successful detach/unregistration and preserve uncertain state rather than delete it. Cover failure ordering with injected behavioral tests before a real import.
5. Disabling systemd offline is a startup measure, not demonstrated network isolation. Prove how the disposable import prevents production contact before first boot, and how Windows files reach WSL's system distro; do not assume its mounts match ordinary `/mnt/c` access. No real isolation trial has passed in this review.
6. Recovery uses one global journal but a distro-specific mutex and does not bind the journal's distro to the requested operation. Review cross-distro overlap and recovery identity before allowing scheduler restoration or journal deletion.
7. Current controller tests mostly inspect source strings for the new coordination/isolation paths. Those checks do not establish crash recovery, startup isolation or safe cleanup behavior.
8. The hidden-input password-test helper remains a retired-Debian3 candidate, including its default target. Static no-fallback assertions are not a private interactive recovery test.

Do not commit the runtime candidate as completed or infer readiness from a passing fast lane. Keep it separate from bootstrap, Terminal and migration-documentation commits.

## Acceptance order

1. Finish the finite data/capability selection and Debian4-specific source contract. Review the candidate findings above and implement focused regression tests without production access.
2. Run the canonical nondestructive fast lane against the exact source and record its limitations. Preserve failed attempts as well as final results.
3. After concrete approval, deploy only reviewed files, preserve installation-specific configuration, and initialize only the new repository with independently protected credentials. Scheduling remains disabled.
4. Create a snapshot and restore into an explicitly new disposable destination using the independently retrieved recovery password, not the installed runtime credential. Verify selected bytes, permissions, SQLite consistency, Git work and secret recoverability without logging secrets.
5. Separately demonstrate the approved whole-distro disposable-import isolation and selected restore landmarks. Hashes alone do not prove restoration. Preserve uncertain cleanup state for review.
6. Enable Linux/systemd scheduling only after the restore evidence is accepted. Windows must not wake WSL for routine backup polling or scheduling.
7. Source retirement remains a separate final unique-data inventory and explicit approval. Keep Debian-Recovered, Debian-Backup, immutable images, existing repositories and recovery staging intact until then.
