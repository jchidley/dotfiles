# Retired Debian3 recovery plan

This document is a historical pointer, not an execution plan. Debian3 was permanently unregistered by explicit owner authorization after the selected comparison found no important unique application data requiring whole-distro retention.

Current Debian4 state and remaining post-closeout work are governed solely by the [Debian4 plan](../../docs/DEBIAN4-PLAN.md), [`STATUS.md`](STATUS.md), and [`TASKS.md`](TASKS.md). Debian-Backup forensic work, fresh-backup assurance, and source retirement are complete. Dated Debian3 evidence remains in the [Debian4 build results](../../docs/DEBIAN4-RESULTS.md) and explicitly historical [Debian3 comparison](../../docs/DEBIAN3-RECOVERED-COMPARISON.md).

Durable requirements retained from the retired plan are incorporated into the active plan:

- routine Linux backup scheduling belongs to Linux/systemd;
- whole-distro export must preserve source state and coordinate with Linux scheduling;
- recovery credentials must be independently recoverable without exposing them;
- secret-bearing archives require agreed protected storage;
- disposable imports must be isolated before first boot;
- failed or interrupted validation must not promote an archive or delete source evidence;
- existing Restic repositories and old archives must not be overwritten, transplanted, or pruned merely to initialize Debian4.

Historical exporter/password candidates remain source evidence only. Do not deploy them as a Debian3 procedure or substitute them for the completed Debian4 backup contract.
