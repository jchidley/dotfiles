# WSL backup scheduling tasks

- [complete] Phase 1 state/policy foundation at commit `542e465`.
- [complete] Phase 2 fixture-only shadow coordinator integrated at commit `d946664`: 38 retained assertions, six attributed semantic mutations, and the canonical fast lane pass.
- [complete] No-op relay `a96508aa-768d-41ab-ba1c-f1766d4e5c7d` closed as `accepted-complete`; its executor changed no project or external state.
- [complete] Production health-state contract approved in [`PRODUCTION-HEALTH-STATE-DECISION.md`](PRODUCTION-HEALTH-STATE-DECISION.md): second consecutive eligible failure/deferral warnings, suspension-independent counters, six-hour same-episode suppression, one tracked policy, and atomic persistence/recovery criteria.
- [complete] Production-state adapter integrated at commit `1e2b97a`: approved policy/state contract, 115 retained assertions, eight attributed semantic mutations, canonical fast lane, controller review, and synchronized Windows/WSL Git history.
- [complete] Phase 3 source-only consent candidate integrated at commit `6a84654`: 55 retained assertions, seven attributed semantic mutations, canonical fast lane, controller review, and synchronized Windows/WSL Git history.
- [superseded, never deployed] Windows-driven Phase 4 coordinator candidate. It was removed after confirming that Windows must not wake WSL for routine Linux-owned work.
- [complete, uncommitted] Linux-owned scheduler and migration source: one `systemd` timer, backup-first Linux coordinator, due retention, Linux locking/atomic state, ordinary setup without enablement, reversible task migration, 30 scheduler and 78 migration assertions, and five attributed semantic mutations in each suite. Repository `AGENTS.md` records the OS-ownership boundary.
- [blocked after safe production inventory] All six exact enabled task definitions were retained and revalidated outside Git. Debian-Recovered currently uses WSL init rather than systemd, so Linux preflight failed closed before installation or cutover. A separately reviewed authorization must enable systemd and restart the distro before migration can continue.
- [deferred] Phase 5 cleanup. Controller authorization is required before deployment, task changes, production operations, or marker changes.

Production tasks, WSL/Restic and maintenance execution, production coordinator state, deployment, and the failed full-data-check marker remain outside the authorized source-only work.
