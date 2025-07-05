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

STEP 4: Create basic session log (medium write)
Create sessions/SESSION_[YYYYMMDD]_[HHMMSS].md:

# Session [YYYYMMDD]_[HHMMSS]
Project: [Name]

## Work Done
[Main accomplishments from todos + git commits]

## Commits
[git log output captured earlier]

## Active Todos
[Copy from CHECKPOINT.md]

STEP 5: Clean up old files (no reading needed)
- Check for any SESSION_*.md files in current directory
- If found, move them to sessions/ without reading content
- This preserves history without adding context

STEP 6: Update HANDOFF.md (medium context)
- Check if CHECKPOINT.md exists and read latest/todos from it
- Read current HANDOFF.md
- Update with:
  - Current timestamp
  - Latest achievement from checkpoint
  - Active todo list from checkpoint
  - Refresh Current State and Next Step
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
1. Track all tool permission requests during this session:
   - Check for tools that were granted permission (you used them)
   - Check for tools that were denied permission (you were blocked)
   - Create a list of new permissions not in .claude/settings.local.json

2. If new permissions found, prompt user:
   "🔧 Tool Permission Update Required
   
   The following tools were used during this session:
   
   ✅ ALLOWED (will be added to allow list):
   - Bash(git status:*)
   - WebFetch(domain:api.example.com)
   
   ❌ DENIED (will be added to deny list):
   - WebFetch(domain:suspicious-site.com)
   
   Do you want to:
   [A] Accept all changes
   [M] Modify selections
   [S] Skip permission updates
   
   Your choice: "

3. If user chooses [M], show each permission individually:
   "Bash(git status:*) - Currently: ALLOWED
   [K] Keep as allowed
   [D] Change to denied
   [S] Skip (don't add to either list)
   Your choice: "

4. Update .claude/settings.local.json based on user choices:
   - Add new allowed permissions to "allow" array
   - Add new denied permissions to "deny" array
   - Preserve existing permissions
   - Ensure no duplicates
   - Reference: https://docs.anthropic.com/en/docs/claude-code/settings

Output:
"Session logged to sessions/SESSION_[timestamp].md
HANDOFF.md updated with current state
Next: [from updated HANDOFF]

Ready for /clear or /compact"

Note: Steps are ordered by context impact. If context runs out, todos are already safe in CHECKPOINT.md for recovery by /start.