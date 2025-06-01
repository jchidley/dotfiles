Check git state:
- Run git branch --show-current
- Run git status  
- Run git log --oneline -5

Check for key files:
1. HANDOFF.md → Read (primary project state)
2. SESSION_CHECKPOINT.md → If exists, session was compacted mid-work
3. TODO.md → Read if exists (active tasks)
4. PROJECT_WISDOM.md → If exists, show last 3-5 insights as reminders
5. CLAUDE.md → Read if exists (project instructions)

Output format:

## Project: [Name from HANDOFF]
Status: [from HANDOFF Current State]
Branch: [git branch] | Changes: [Yes/No]

Current focus: [If SESSION_CHECKPOINT exists, use its Task; else use HANDOFF Next Step]

[If PROJECT_WISDOM.md exists with insights:]
Recent learnings:
• [Last insight title]: [Impact in one line]
• [Second-to-last insight]: [Impact]
[Show up to 3-5 most recent]

Ready to: [specific action]

💡 Reminder: See WORKING_WITH_CLAUDE.md for collaboration tips

For new work (no HANDOFF.md):
- Create HANDOFF.md with structure:
  # Project: [Name]
  Updated: [Timestamp]
  
  ## Current State
  Status: Initial setup
  Target: [To be defined]
  Latest: Starting new work
  
  ## Essential Context
  - [To be filled]
  
  ## Next Step
  Define project goals

- Output: "Starting new work session. What would you like to work on?"