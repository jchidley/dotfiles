# /wrap-session

Finalizes session work with minimal context usage by prioritizing critical saves first.

cd <working directory from environment info>

STEP 1: Create safety net (minimal context)
- Use TodoRead tool to get current todo state
- Immediately write CHECKPOINT.md with todos + latest achievement
- This ensures todos are safe even if wrap-session fails

STEP 2: Capture git state (small context)
- Run git status to check for uncommitted changes
- Run git log --oneline -10 to capture recent commits
- If uncommitted changes exist, note for user reminder

STEP 3: Create session directory (tiny context)
- Check if sessions/ directory exists
- If not, create it with: mkdir -p sessions

STEP 3.5: Track Key Documents (new - small context)
Identify key documents created/modified this session:
- Check for new wip-claude/*.md files with today's date
- Note documents mentioned in completed todos
- Include any cleaned/refactored versions ready for implementation
- Keep list minimal (3-5 most important documents)

STEP 4: Create comprehensive session log (medium write)
Create sessions/SESSION_[YYYYMMDD]_[HHMMSS].md:

# Session [YYYYMMDD]_[HHMMSS]
Project: [Name]

## Work Done
[Main accomplishments from todos + git commits]

## Key Documents
[Important files created/modified with descriptions]
- path/to/document.md - Brief description of purpose

## Commits
[git log output captured earlier]

## Active Todos
[Copy from CHECKPOINT.md]

STEP 5: Clean up old files (no reading needed)
- Check for any SESSION_*.md files in current directory
- If found, move them to sessions/ without reading content
- This preserves history without adding context

STEP 6: Update HANDOFF.md with reload guidance (medium context)
- Check if CHECKPOINT.md exists and read latest/todos from it
- Read current HANDOFF.md
- Update with:
  - Current timestamp
  - Latest achievement from checkpoint
  - Active todo list from checkpoint
  - Refresh Current State and Next Step
- ADD new section before "Related Documents":
  ## Context Reload After Clear
  Essential documents for continuing work:
  1. HANDOFF.md - This file (project state and todos)
  2. [Key document 1] - [Purpose]
  3. [Key document 2] - [Purpose]
- If update succeeds, delete CHECKPOINT.md

STEP 7: Check for uncommitted changes reminder
If uncommitted changes were detected in Step 2:
- Output: "⚠️ Uncommitted changes detected. Consider committing before ending session."

STEP 8: Review for wisdom capture (large context - optional)
Only if context allows:
- Check if CURRENT_PROJECT_WISDOM.md exists in working directory
- Review session for wisdom patterns using wisdom-triggers.md
- Suggest any insights found to user
- If user agrees, append to CURRENT_PROJECT_WISDOM.md

STEP 9: Tool Permission Management (if context allows)
[Keep existing permission management logic unchanged]

Output:
"Session logged to sessions/SESSION_[timestamp].md
HANDOFF.md updated with current state
Next: [from updated HANDOFF]

📋 To continue after /clear, reload:
1. HANDOFF.md (project state)
2. [Key document 1 from Context Reload section]
3. [Key document 2 from Context Reload section]
[List up to 3-4 most essential documents]

Ready for /clear or /compact"

Note: Steps are ordered by context impact. If context runs out, todos are already safe in CHECKPOINT.md for recovery by /start.