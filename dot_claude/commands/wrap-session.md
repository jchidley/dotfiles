# /wrap-session

Finalizes session work with minimal context usage by prioritizing critical saves first.

cd <working directory from environment info>

Get timestamp early: `TIMESTAMP=$(date +%Y%m%d_%H%M%S)`
Get formatted date: `CURRENT_DATE=$(date +"%Y-%m-%d %H:%M")`

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
- Create sessions/SESSION_${TIMESTAMP}.md:

# Session ${TIMESTAMP}
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

STEP 6: Validate and create key documents (small context)
Check for and create missing key project documents, tracking what was created:

Initialize empty list: CREATED_DOCS=()

a) If HANDOFF.md doesn't exist:
   - Get project name from git remote or directory name
   - Create minimal HANDOFF.md:
     ```
     # Project: [Name]
     Updated: ${CURRENT_DATE}
     
     ## Current State
     Status: New session
     Target: [To be defined]
     Latest: Starting work
     
     ## Essential Context
     - [To be filled during work]
     
     ## Next Step
     Define project goals
     
     ## Active Todo List
     [Will be populated from todos]
     
     ## Context Reload After Clear
     Essential documents for continuing work:
     1. HANDOFF.md - This file (project state and todos)
     ```
   - Add to CREATED_DOCS: "HANDOFF.md"
   - Echo: "✨ Created HANDOFF.md for session continuity"

b) If CURRENT_PROJECT_WISDOM.md doesn't exist:
   - Create empty file with header:
     ```
     # Project Wisdom
     
     Lessons learned and patterns discovered during development.
     ```
   - Add to CREATED_DOCS: "CURRENT_PROJECT_WISDOM.md"
   - Echo: "✨ Created CURRENT_PROJECT_WISDOM.md for capturing insights"

c) If WORKING_WITH_CLAUDE.md doesn't exist:
   - Check if ~/.claude/WORKING_WITH_CLAUDE.md exists
   - If yes, create symlink: `ln -s ~/.claude/WORKING_WITH_CLAUDE.md .`
     - Add to CREATED_DOCS: "WORKING_WITH_CLAUDE.md (symlink)"
     - Echo: "✨ Created WORKING_WITH_CLAUDE.md symlink to global version"
   - If no, echo: "💡 Consider creating WORKING_WITH_CLAUDE.md for collaboration tips"

If any documents were created, echo summary:
"📄 Created ${#CREATED_DOCS[@]} key documents this session"

STEP 7: Update HANDOFF.md (medium context)
- Check if CHECKPOINT.md exists and read latest/todos from it
- Read current HANDOFF.md (now guaranteed to exist)
- Get current date/time: `CURRENT_DATE=$(date +"%Y-%m-%d %H:%M")`
- Update with:
  - Current timestamp using ${CURRENT_DATE}
  - Latest achievement from checkpoint
  - Active todo list from checkpoint (remove completed items)
  - Refresh Current State and Next Step
  - Update "Context Reload After Clear" section by analyzing:
    1. What was worked on in this session (from todos, git, and session notes)
    2. Previous context documents from HANDOFF.md (check if still relevant)
    3. New wip-claude documents created this session
    4. Relevance to active (non-completed) todos
    - Include only documents that are relevant to ongoing work
    - Format as simple list:
    ```
    ## Context Reload After Clear
    Key wip-claude documents:
    - wip-claude/YYYYMMDD_HHMMSS_description.md
    - [other relevant documents with full paths]
    ```
- If update succeeds, delete CHECKPOINT.md

STEP 8: Check for uncommitted changes reminder
If uncommitted changes were detected in Step 2:
- Output: "⚠️ Uncommitted changes detected. Consider committing before ending session."

STEP 9: Document availability report (small context)
List available key documents for next session:
- "📚 Key Documents Available:"
- If HANDOFF.md exists: "  ✓ HANDOFF.md - Project state and todos"
- If CURRENT_PROJECT_WISDOM.md exists: "  ✓ CURRENT_PROJECT_WISDOM.md - Development insights"
- If CLAUDE.md exists: "  ✓ CLAUDE.md - Project-specific instructions"
- If sessions/ has files: "  ✓ sessions/ - [count] historical logs"
- If wip-claude/ has files: "  ✓ wip-claude/ - [count] working documents"

Also check for and report any critical missing documents:
- If no .gitignore: "  ⚠️ Missing .gitignore - consider adding"
- If no README.md: "  ⚠️ Missing README.md - consider documenting project"

STEP 10: Review for wisdom capture (large context - optional)
Only if context allows:
- Check if CURRENT_PROJECT_WISDOM.md exists in working directory
- Review session for wisdom patterns using wisdom-triggers.md
- Suggest any insights found to user
- If user agrees, append to CURRENT_PROJECT_WISDOM.md

STEP 11: Tool Permission Management (if context allows)
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
"Session logged to sessions/SESSION_${TIMESTAMP}.md
HANDOFF.md updated with current state
Next: [from updated HANDOFF]

Ready for /clear or /compact"

Note: Steps are ordered by context impact. If context runs out, todos are already safe in CHECKPOINT.md for recovery by /start.