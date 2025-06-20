Check git state:
- Run git branch --show-current
- Run git status  
- Run git log --oneline -5

Check for key files:
1. HANDOFF.md → Read (primary project state)
2. SESSION_CHECKPOINT.md → If exists, session was compacted mid-work
3. TODO.md → Read if exists (active tasks)

Restore/merge todo list from HANDOFF.md:
1. FIRST use TodoRead to check if you already have active todos
2. Look for "## Active Todo List" section in HANDOFF.md
3. Parse HANDOFF.md todo items with these status indicators:
   - [ ] = pending
   - [⏳] = in_progress
   - [✓] = completed
4. Apply merge logic:
   - If current todo list is empty: restore all from HANDOFF.md
   - If current todo list exists: merge intelligently
     a. For each HANDOFF.md todo, check if content already exists in current list
     b. If not exists: add it with status from HANDOFF.md
     c. If exists with different status: keep the MORE ADVANCED status
        (hierarchy: completed > in_progress > pending)
     d. Never duplicate todos by content
     e. Preserve all current todos even if not in HANDOFF.md
5. Use TodoWrite with the merged list, assigning new unique IDs
6. If no Active Todo List in HANDOFF.md, check TODO.md as fallback

Example merge scenarios:
- Current: ["Fix bug X" - in_progress], HANDOFF: ["Fix bug X" - pending] → Keep in_progress
- Current: ["Add feature Y" - pending], HANDOFF: ["Add feature Y" - completed] → Update to completed
- Current: ["Task A"], HANDOFF: ["Task A", "Task B"] → Result: ["Task A", "Task B"]

Output format:

## Project: [Name from HANDOFF]
Status: [from HANDOFF Current State]
Branch: [git branch] | Changes: [Yes/No]

Current focus: [If SESSION_CHECKPOINT exists, use its Task; else use HANDOFF Next Step]

Ready to: [specific action]

[If todos were restored/merged:]
Active todos: [X pending, Y in progress, Z completed]
[If merge happened:] (merged [N] todos from HANDOFF.md, [M] were new/updated)

💡 Reminder: See WORKING_WITH_CLAUDE.md for collaboration tips
💭 Watch for insights to capture with /checkpoint (solutions, patterns, fixes)

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