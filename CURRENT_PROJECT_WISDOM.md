# Current Project Wisdom

Raw insights captured during sessions for later refinement by /clean-wisdom.

### 2025-07-09: Hook Implementation Pattern - PreToolUse Hooks Enforce CORE Patterns
**Insight**: PreToolUse hooks can automatically enforce CORE patterns discovered through wisdom analysis. Implemented validators for Chezmoi source discipline and working directory management that prevent common errors before they happen.
**Impact**: Shifts enforcement from documentation/memory to automatic validation. Users get immediate feedback with actionable error messages.
**Note**: Hook architecture allows gradual addition of validators as patterns are discovered and validated through usage.

### 2025-07-09: Clean-wisdom Success - 32 Sessions Distilled to Actionable Patterns
**Insight**: Successfully ran /clean-wisdom on 32 session files, extracting patterns through repetition analysis. Patterns with 6+ occurrences became CORE, 3-5 became established, 1-2 emerging.
**Impact**: Transformed scattered insights into structured, prioritized patterns with copy-paste ready implementations and evolution tracking.
**Note**: Most repeated pattern (Chezmoi Source File Discipline, 10+ occurrences) validated the importance of the pattern and justified hook implementation.

### 2025-07-09: Timestamp Fix Pattern - System Time Over Placeholders
**Insight**: Commands using placeholder timestamps like [YYYYMMDD] cause confusion. Fixed by using `$(date +format)` to get actual system time at command execution.
**Impact**: /wrap-session and /checkpoint now create files with accurate timestamps automatically, no manual intervention needed.
**Note**: Simple fix but important for session tracking and chronological ordering.

### 2025-07-09: CORE Pattern Hook Architecture - Gradual Enforcement Strategy
**Insight**: Not all patterns need hooks immediately. Start with highest-impact patterns (CORE 6+ occurrences), implement as PreToolUse validators, gather feedback, then expand.
**Impact**: Pragmatic approach to automation - enforce patterns that cause most pain first, learn from usage, iterate.
**Note**: 2 of 4 CORE patterns now have hooks. Remaining 2 (command quality, separation of concerns) require different approaches.

### 2025-07-10: Session Document Coordination - Close the Loop
**Insight**: /wrap-session creates documents and maintains "Context Reload After Clear" but /start doesn't use this information. Fixed by making wrap-session report created docs and auto-update reload list, while start displays available context docs.
**Impact**: Seamless context restoration between sessions. No more wondering which documents to reload or missing key context.
**Note**: Commands should coordinate - what one command prepares, another should use. Document creation → tracking → restoration forms complete loop.