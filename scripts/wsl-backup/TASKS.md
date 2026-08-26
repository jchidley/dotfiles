# WSL backup scheduling tasks

- [complete] Phase 1 state/policy foundation and read-only dry-run: the exact Windows source passed `./scripts/wsl-backup/test-all fast` from WSL, with 44 home assertions, 19 system assertions, and no PSScriptAnalyzer findings.
- [deferred] Phase 2 routine coordinator; requires controller authorization after review of the Phase 1 changes and documentation.

The separate canonical WSL checkout remains dirty and differs from the Windows source, but its own fast lane also passes. No production scheduling or maintenance work was started.
