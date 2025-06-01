# Project Wisdom

Insights and lessons learned from development.

## Active Insights (Recent & Critical)

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