# Retired Debian3 recovery plan

This document is a historical pointer, not an execution plan. Debian3 was permanently unregistered by explicit owner authorization after the selected comparison found no important unique application data requiring whole-distro retention.

Current Debian4 capability/data selection, Debian-Backup forensic preservation, and fresh-backup work are governed solely by the [Debian4 plan](../../docs/DEBIAN4-PLAN.md). Dated Debian3 evidence remains in [`STATUS.md`](STATUS.md), the [Debian4 build results](../../docs/DEBIAN4-RESULTS.md), and the explicitly historical [Debian3 comparison](../../docs/DEBIAN3-RECOVERED-COMPARISON.md).

Durable requirements retained from the retired plan are incorporated into the active plan:

- routine Linux backup scheduling belongs to Linux/systemd;
- whole-distro export must preserve source state and coordinate with Linux scheduling;
- recovery credentials must be independently recoverable without exposing them;
- secret-bearing archives require agreed protected storage;
- disposable imports must be isolated before first boot;
- failed or interrupted validation must not promote an archive or delete source evidence;
- existing Restic repositories and old archives must not be overwritten, transplanted, or pruned merely to initialize Debian4.

The unfinished local exporter/password candidate remains source work for review. It must not be deployed as a Debian3 procedure or treated as the Debian4 recovery contract without adapting it to Debian4's deliberately selected contents.
