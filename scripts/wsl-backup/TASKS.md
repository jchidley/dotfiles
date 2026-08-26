# WSL backup scheduling tasks

- [complete] Phase 1 state/policy foundation at commit `542e465`.
- [complete] Phase 2 fixture-only shadow coordinator integrated at commit `d946664`: 38 retained assertions, six attributed semantic mutations, and the canonical fast lane pass.
- [complete] No-op relay `a96508aa-768d-41ab-ba1c-f1766d4e5c7d` closed as `accepted-complete`; its executor changed no project or external state.
- [complete] Production health-state contract approved in [`PRODUCTION-HEALTH-STATE-DECISION.md`](PRODUCTION-HEALTH-STATE-DECISION.md): second consecutive eligible failure/deferral warnings, suspension-independent counters, six-hour same-episode suppression, one tracked policy, and atomic persistence/recovery criteria.
- [next, authorization required] Implement and prove the production adapter against the approved disposable acceptance contract. This requires a separate bounded authorization and does not authorize deployment or production operations.
- [deferred] Phase 3 consent and long-job execution, Phase 4 production migration, and Phase 5 cleanup. Controller authorization is required before selecting or starting a later phase.

Production tasks, Restic and maintenance execution, production coordinator state, deployment, commit, and push are outside the completed fixture-only action.
