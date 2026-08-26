# WSL backup scheduling tasks

- [complete] Phase 1 state/policy foundation and read-only dry-run at commit `542e465`; the exact Windows source passed the fast gate.
- [next] Harden the Phase 2 shadow candidate: track awake time since the previous attempt; keep a single lock deferral non-alerting and due; block maintenance selection after backup deferral/failure; prove suspension affects neither due time nor health; and make each mutation fail through its intended retained assertion rather than an incidental exception.
- [blocked] Reconcile the stale configured remote-tracking ref before any integration, commit, or push decision; fresh remote `main` is `84e7e578d27bceddad555d8169e9aeab6a71d98e` (`Standardize repository roots and shell startup`).
- [deferred] Phase 3 consent and long-job execution, Phase 4 production migration, and Phase 5 cleanup.

Production tasks, Restic and maintenance execution, production coordinator state, deployment, commit, and push are outside the next action.
