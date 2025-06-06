# Project Wisdom

Insights and lessons learned from development.

## Active Insights (Recent & Critical)

### 2025-01-06: Temporary Documentation Strategy - wip-claude Folder for Planning Artifacts  
Insight: Creating a dedicated wip-claude/ folder with timestamped markdown files provides a structured approach to planning and documentation. Files serve dual purposes: instructions for Claude AND human-readable documentation. The timestamp naming (YYYYMMDD_HHMMSS_description.md) ensures clear chronology and prevents overwrites.
Impact: Complex tasks now have a standard workflow for creating plans, reviews, reports, and explanations. This creates an audit trail of decision-making and improves handoff between sessions while keeping temporary work separate from permanent documentation.

### 2025-01-06: Todo List Persistence - Smart Merge Strategy Prevents Data Loss
Insight: Claude's todo list can be lost between sessions or after /compact. Implementing a merge strategy in /start (rather than simple overwrite) preserves both current session todos and recovered HANDOFF.md todos, using status hierarchy (completed > in_progress > pending) to resolve conflicts.
Impact: Todo context persists reliably across sessions. The merge strategy prevents duplicate todos while ensuring no work is lost, even when /start is run mid-session with existing todos.

### 2025-06-01: Chezmoi Directory Naming - Avoid Nested dot_ Structures
Insight: Creating dot_claude/dot_claude/ in chezmoi source results in ~/.claude/.claude/ in the target, which is confusing and unnecessary. Chezmoi's dot_ prefix transformation should only be used at the top level of managed directories.
Impact: Configuration files should be placed directly in dot_claude/, not in nested dot_claude/dot_claude/. This prevents duplicate directory structures and maintains clarity about source vs target paths.

### 2025-06-01: Tool Permissions - Interactive Bulk Approval System
Insight: Claude Code's tool permissions can be tracked during sessions and bulk-approved interactively, eliminating the friction of approving each tool use individually. The system tracks both allowed and denied permissions separately.
Impact: Future sessions will have pre-approved permissions via .claude/settings.local.json, significantly improving workflow efficiency and reducing interruptions during development.

### 2025-06-01: Command Instructions - Proactive Suggestions Improve Capture
Insight: Modified commands to suggest specific insights rather than relying on Claude to recognize "significant discoveries". Providing concrete examples and patterns makes it much more likely that valuable insights will be captured.
Impact: PROJECT_WISDOM.md will grow organically with real discoveries instead of being forgotten when Claude focuses on completing tasks.

### 2025-06-01: Slash Commands - User Instructions Drive Claude Actions
Insight: Slash commands in Claude Code work by displaying instructions that Claude reads and executes, not through special parsing or APIs. The command content is what guides Claude's behavior.
Impact: Command design should focus on clear, actionable instructions that Claude can follow, with specific examples and patterns to look for.

### 2025-06-01: Conditional Logic Visibility - Buried Instructions Get Skipped
Insight: Important actions in commands need to be prominent and have clear triggers, not hidden in conditional blocks. The PROJECT_WISDOM.md update was buried under "If significant discovery occurred" which made it easy to skip.
Impact: Critical actions should be explicit steps with clear prompts, not optional conditions that require subjective judgment.

### 2025-06-01: Interactive Prompts - Explicit Questions Drive Action
Insight: Asking users directly "Did you learn anything?" or "Add these insights?" is more effective than hoping they'll remember to document insights. Direct questions with specific suggestions get responses.
Impact: Commands should ask explicit questions with concrete examples rather than rely on users or AI to spontaneously remember optional actions.

### 2025-05-31: Human-AI Collaboration - Magic Phrases Over Automation
Insight: The key to avoiding repeated mistakes isn't more automation - it's better human-AI collaboration. By documenting "magic phrases" and reminding humans when to guide AI searches, we leverage each partner's strengths.
Impact: Created WORKING_WITH_CLAUDE.md to guide human-side patterns, reducing repeated errors through gentle reminders rather than complex automation.

### 2025-06-01: Chezmoi Ignore Patterns - Selective Directory Management
Insight: When managing configuration directories with chezmoi (like .claude/), you can selectively ignore runtime subdirectories while managing config files by listing specific paths in .chezmoiignore (e.g., `.claude/todos/` instead of `.claude/`).
Impact: Allows version control of important config while excluding dynamic runtime data, preventing repository bloat and merge conflicts.

### 2025-06-01: Session Checkpoint Workflow - Preserve Context Not Delete
Insight: The SESSION_CHECKPOINT.md file contains valuable mid-session context that should be incorporated into the final session log, not blindly deleted. The checkpoint command creates it for post-/compact restoration.
Impact: Wrap-session command should check for and merge checkpoint content into the final session log to preserve complete session history.

### 2025-06-01: Multiple Checkpoints - Unique Filenames Prevent Data Loss
Insight: Users may run checkpoint multiple times during a session. Using a single SESSION_CHECKPOINT.md filename causes later checkpoints to overwrite earlier ones. Timestamped filenames (SESSION_CHECKPOINT_HHMMSS.md) preserve all checkpoints.
Impact: Both checkpoint and wrap-session commands now handle multiple checkpoint files, ensuring no mid-session context is lost. The pattern SESSION_*.md catches all checkpoint files for incorporation.

### 2025-06-02: Command Effectiveness - Instruction Detail Matters
Insight: The /req commands went from ineffective (30 sparse lines) to robust (200+ detailed lines) by adding explicit step-by-step instructions, validation logic, and comprehensive error handling. Command effectiveness directly correlates with instruction detail.
Impact: When writing Claude Code slash commands, invest in detailed instructions with specific examples, edge cases, and clear decision trees. More detail = better execution.

### 2025-06-02: Natural Command Patterns - Implicit Over Explicit
Insight: Users prefer natural patterns like `/req <description>` over explicit subcommands like `/req add <description>`. The primary use case should be implicit, with subcommands only for secondary functions.
Impact: Design commands with the most common usage as the default pattern. This reduces cognitive load and makes commands feel more intuitive.