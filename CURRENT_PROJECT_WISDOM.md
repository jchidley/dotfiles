# Current Project Wisdom

Raw insights captured during sessions for later refinement by /clean-wisdom.

### 2025-07-02: Session Command Directory Independence - Working Directory Management Pattern
**Insight**: Session commands were directory-unsafe, creating files in wrong locations if Claude navigated to subdirectories during work. Fixed by adding explicit cd to project root using environment working directory reference.
**Impact**: Session files (HANDOFF.md, SESSION_*.md, REQUIREMENTS.md, PROJECT_WISDOM.md) now consistently managed in correct location regardless of Claude's navigation.
**Note**: Working Directory Management elevated to CORE pattern through repetition analysis - found 6+ occurrences across sessions.

### 2025-07-02: Pattern Distillation Success - First Clean-Wisdom Execution  
**Insight**: Successfully analyzed 25+ sessions spanning 2025-01-06 to 2025-07-02, identifying 3 CORE patterns, 4 established patterns, and 2 emerging patterns through repetition analysis. Created refined PROJECT_WISDOM.md with proper emphasis based on occurrence frequency.
**Impact**: Established working pattern distillation process that converts raw session insights into actionable, copy-paste ready patterns with context and evolution tracking.
**Note**: Most repeated pattern was Chezmoi Source File Discipline (7+ occurrences), validating the importance of source vs deployed file distinction.

### 2025-07-02: Universal Principles with Implementation-Specific Tooling
**Insight**: Core principles like "always edit source files, never deployed files" apply universally, but implementation differs by user type. Humans use `chezmoi edit` command, Claude uses Read/Edit/Write tools on source files directly. The directory structure principle is what matters.
**Impact**: Patterns can be more accurate by distinguishing universal principles from implementation details, making them useful for both human and AI collaboration.
**Note**: Updated Chezmoi Source File Discipline pattern to reflect both approaches while maintaining the core insight about source-to-target deployment model.

### 2025-07-02: UX Enhancement - Contextual Workflow Prompts
**Insight**: Adding optional prompts at the end of commands suggests natural next steps without forcing automation
**Impact**: Users get workflow guidance while maintaining control over when to extend their work
**Note**: Enhanced /clean-wisdom with cross-project analysis prompt. Better than automatic scanning

### 2025-07-02: UX Design - Optional Suggestions vs Automatic Features
**Insight**: Prompts for related actions preserve user agency while preventing missed opportunities
**Impact**: Avoids feature creep and complexity while still surfacing valuable workflow extensions
**Note**: Chose prompt-based approach over automatic cross-directory scanning for /clean-wisdom enhancement

### 2025-01-05: Command Clarity - Eliminating "Project Root" Ambiguity
**Insight**: The term "project root" in /wrap-session and /checkpoint commands caused confusion when Claude was invoked from subdirectories. Claude interpreted it as parent directory instead of the initial working directory.
**Impact**: Commands failed with security errors when trying to cd to parent directories. Fixed by replacing all "project root" references with explicit "cd <working directory from environment info>".
**Note**: Simple, explicit instructions prevent interpretation errors. The working directory from environment info is fixed at Claude start and never changes.