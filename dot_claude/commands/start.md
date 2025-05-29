Check git state:
- Run git branch --show-current
- Run git status  
- Run git log --oneline -5

Check for key files in order:
- If HANDOFF.md exists → Read it (primary context)
- If TODO.md exists → Read it (active tasks)
- If plan.md exists → Note strategic direction
- If PROJECT_WISDOM.md exists → Note its presence
- If CLAUDE.md exists → Read it (project instructions)
- If README.md exists → Scan briefly

For continuing work (HANDOFF.md exists):
Output:
## Project: [Name]
Branch: [current branch]
Current Status: [from HANDOFF.md]
Uncommitted Changes: [Yes/No - summary if yes]

Recent Progress:
- [Last commit or accomplishment]
- [Key metric if applicable]

Next Actions:
1. [Primary task from HANDOFF.md]
2. [High priority from TODO.md if exists]

Ready to proceed with: [specific next task]

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