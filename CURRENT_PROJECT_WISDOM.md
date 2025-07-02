# Current Project Wisdom

Raw insights captured during sessions for later refinement by /clean-wisdom.

### 2025-07-02: Command Refactoring - Extract shared patterns to single source
**Insight**: When multiple commands contain identical instruction blocks (like wisdom capture patterns in checkpoint.md and wrap-session.md), extract them to a dedicated reference file that commands can point to.
**Impact**: Eliminates duplication, ensures consistency, and makes updates easier - change once, apply everywhere.
**Note**: Created wisdom-triggers.md as the single source for wisdom capture patterns, referenced by both checkpoint and wrap-session commands.

### 2025-07-02: DRY principle - Central reference file for command patterns  
**Insight**: Commands should contain only procedural instructions, while domain knowledge (what patterns to look for, formatting rules) belongs in a separate reference file that multiple commands can share.
**Impact**: Creates proper separation of concerns - commands focus on "how to execute", reference files contain "what to look for".
**Note**: This pattern could apply to other shared command elements like error handling patterns or validation rules.