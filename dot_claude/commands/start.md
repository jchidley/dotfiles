Check git state:
- Run git branch --show-current
- Run git status (note if working tree is clean or has changes)
- Run git log --oneline -5

Check for key files:
1. ./CHECKPOINT.md → Check if exists (safety net from interrupted session)
   - If found: Read it for todos and latest achievement
   - This takes precedence over HANDOFF.md as most recent state
   
2. ./HANDOFF.md → Read if exists (ONLY in current directory, NEVER parent directories)
   - If not found: Ask user "No HANDOFF.md found in current directory. Create new project handoff? (y/n)"
   - Only create if user confirms with 'y' or 'yes'

Restore/merge todo list (prioritizing CHECKPOINT.md if exists):
1. FIRST use TodoRead to check if you already have active todos
2. If CHECKPOINT.md exists:
   - Parse todos from "## Todos" section
   - Use these as the source of truth (most recent)
   - Delete CHECKPOINT.md after successful merge
3. Otherwise, look for "## Active Todo List" section in HANDOFF.md
4. Parse todo items with these status indicators:
   - [ ] = pending
   - [⏳] = in_progress
   - [✓] = completed
5. Apply merge logic:
   - If current todo list is empty: restore all from source
   - If current todo list exists: merge intelligently
     a. For each source todo, check if content already exists in current list
     b. If not exists: add it with status from source
     c. If exists with different status: keep the MORE ADVANCED status
        (hierarchy: completed > in_progress > pending)
     d. Never duplicate todos by content
     e. Preserve all current todos even if not in source
6. Use TodoWrite with the merged list, assigning new unique IDs

Example merge scenarios:
- Current: ["Fix bug X" - in_progress], HANDOFF: ["Fix bug X" - pending] → Keep in_progress
- Current: ["Add feature Y" - pending], HANDOFF: ["Add feature Y" - completed] → Update to completed
- Current: ["Task A"], HANDOFF: ["Task A", "Task B"] → Result: ["Task A", "Task B"]

Check for context reload suggestions:
- If HANDOFF.md has "## Context Reload After Clear" section:
  - Extract the document list exactly as written
  - Echo it to the user without reading any files

Output format:

## Project: [Name from HANDOFF]
Status: [from HANDOFF Current State]
Branch: [git branch] | Changes: [Yes/No based on git status - "No" if clean]

Current focus: [from HANDOFF Next Step]

Ready to: [specific action]

[If todos were restored/merged:]
Active todos: [X pending, Y in progress, Z completed]
[If merge happened:] (merged [N] todos from HANDOFF.md, [M] were new/updated)
[If checkpoint recovered:] (recovered from CHECKPOINT.md - session was interrupted)

[If context reload section found:]
📚 Key context from last session:
[Echo the exact content from HANDOFF.md Context Reload section]

💡 Reminder: See WORKING_WITH_CLAUDE.md for collaboration tips
💭 Watch for insights to capture with /wrap-session (solutions, patterns, fixes)

For new work (when user confirms creation of HANDOFF.md):
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
  
  ## Active Todo List
  - [ ] Define project requirements
  - [ ] Set up initial structure
  
  ## If Blocked
  None - just starting
  
  ## Context Reload After Clear
  Essential documents for continuing work:
  1. HANDOFF.md - This file (project state and todos)
  
  ## Related Documents
  - CLAUDE.md - Project instructions (if exists)
  - PROJECT_WISDOM.md - Development insights (if exists)

- Output: "Starting new work session. What would you like to work on?"
- Echo: "✨ Created HANDOFF.md for session continuity"

If user declines HANDOFF.md creation:
- Output: "Starting work session without HANDOFF.md. What would you like to work on?"