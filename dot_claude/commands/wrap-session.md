Create sessions directory if it doesn't exist:
- Check if sessions/ directory exists
- If not, create it with: mkdir -p sessions

Clean up checkpoint:
- Delete SESSION_CHECKPOINT.md if exists

Create sessions/SESSION_[YYYYMMDD]_[HHMMSS].md:

# Session [YYYYMMDD]_[HHMMSS]
Project: [Name]

## Work Done
[List what was actually accomplished - focus on completions]

## Failed Approaches
[Only if any - what didn't work and why]

## Commits
[git log --oneline output for this session]

Update HANDOFF.md:
- Refresh "Current State" with final status
- Update "Latest" with session's main achievement
- Ensure "Next Step" is current for next session (consider pending REQUIREMENTS.md items)
- Clear "If Blocked" if resolved

Check for uncommitted changes:
- Run git status
- If changes exist, remind: "Uncommitted changes detected. Consider committing before ending session."

Review session and update PROJECT_WISDOM.md:
1. Check session log "Technical Insights" section for discoveries
2. Look for these patterns in the work done:
   - Tool/command discoveries: "Found [tool] works better with [approach]"
   - Error solutions: "Fixed [error] by [solution]"
   - Configuration insights: "[Setting] must be [value] because [reason]"
   - Workflow improvements: "[New approach] prevents [problem]"
   - Integration findings: "[Tool A] and [Tool B] interact via [mechanism]"

3. If insights found, suggest specific entries:
   "💡 Add these to PROJECT_WISDOM.md?
   - [Concrete suggestion based on session]
   - [Another if applicable]"

4. Update PROJECT_WISDOM.md with user-approved insights

5. Archive if > 5KB:
   - Create PROJECT_WISDOM_ARCHIVE_[YYYYMMDD].md
   - Move older insights (keep last 10-15 active)
   - Add archive note to header

Check for cleanup:
- If SESSION_*.md files exist in root: "Run 'mv SESSION_*.md sessions/' to organize"

Tool Permission Management:
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
Next: [from updated HANDOFF]
Ready for /clear

💭 Next session: If working on similar tasks, remind Claude to check history"