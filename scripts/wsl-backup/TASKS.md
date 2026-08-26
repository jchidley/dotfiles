# WSL backup scheduling tasks

- [complete] Phase 1 state/policy foundation at commit `542e465`.
- [complete] Phase 2 fixture-only shadow coordinator integrated at commit `d946664`: 38 retained assertions, six attributed semantic mutations, and the canonical fast lane pass.
- [next] Close no-op relay `a96508aa-768d-41ab-ba1c-f1766d4e5c7d` as `accepted-complete`; its executor changed no project or external state.
- [blocked] Before production-state integration, approve production failure/deferral warning thresholds and prove the adapter atomically persists projected consecutive counters across real coordinator runs.
- [deferred] Phase 3 consent and long-job execution, Phase 4 production migration, and Phase 5 cleanup. Controller authorization is required before selecting or starting a later phase.

Production tasks, Restic and maintenance execution, production coordinator state, deployment, commit, and push are outside the completed fixture-only action.
