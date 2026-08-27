# WSL backup scheduling tasks

- [complete] Phase 1 state/policy foundation at commit `542e465`.
- [complete] Phase 2 fixture-only shadow coordinator integrated at commit `d946664`: 38 retained assertions, six attributed semantic mutations, and the canonical fast lane pass.
- [complete] No-op relay `a96508aa-768d-41ab-ba1c-f1766d4e5c7d` closed as `accepted-complete`; its executor changed no project or external state.
- [complete] Production health-state contract approved in [`PRODUCTION-HEALTH-STATE-DECISION.md`](PRODUCTION-HEALTH-STATE-DECISION.md): second consecutive eligible failure/deferral warnings, suspension-independent counters, six-hour same-episode suppression, one tracked policy, and atomic persistence/recovery criteria.
- [complete] Production-state adapter integrated at commit `1e2b97a`: approved policy/state contract, 115 retained assertions, eight attributed semantic mutations, canonical fast lane, controller review, and synchronized Windows/WSL Git history.
- [complete, pending source integration] Phase 3 source-only consent candidate: 55 retained assertions, seven attributed semantic mutations, canonical fast lane, controller review, and no production adapters or effects.
- [next, authorization required] Commit and push the reviewed Phase 3 source, policy, tests, fast-lane hook, and factual documentation; then fast-forward the WSL chezmoi checkout through Git. Exclude `NEXT-SESSION.md`.
- [deferred] Phase 4 production migration and Phase 5 cleanup. Controller authorization is required before selecting or starting either phase.

Production tasks, WSL/Restic and maintenance execution, production coordinator state, deployment, and the failed full-data-check marker remain outside the authorized source-only work.
