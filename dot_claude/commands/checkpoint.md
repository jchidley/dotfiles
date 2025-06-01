Create SESSION_CHECKPOINT_[HHMMSS].md (timestamped to support multiple checkpoints):

# Session Checkpoint [HHMMSS]
Created: [Current timestamp]
Task: [One line description of current task]
Progress: [What's been done since last checkpoint - 1-2 lines max]
Next: [Immediate next action]

## Work Done
[List specific accomplishments since last checkpoint]

## Failed Approaches
[Any approaches that didn't work since last checkpoint]

Note: This file will be incorporated into final session log by /wrap-session

Update HANDOFF.md with current timestamp:

# Project: [Current project name]
Updated: [Current timestamp]

## Current State
Status: [Key metric/progress]
Target: [What we're aiming for]
Latest: [Most recent accomplishment/discovery]

## Essential Context
- [Critical fact 1]
- [Critical fact 2]
- [Critical fact 3]
(Max 5 bullets - only what's needed RIGHT NOW)

## Next Step
[THE one thing to do next]

## If Blocked
[What's stopping progress, if anything]

## Failed Approaches
[Document what hasn't worked to avoid repeating dead ends]
- [Failed approach 1]: [Why it didn't work]
- [Failed approach 2]: [Why it didn't work]
(Include specific error messages or technical reasons)

## Related Documents
- REQUIREMENTS.md - Project requirements
- TODO.md - Active tasks  
- CLAUDE.md - Project instructions

Review session for PROJECT_WISDOM.md updates:
1. Check for these common insight patterns:
   - Tool usage patterns: "Found that [tool] works better with [specific approach]"
   - Error solutions: "Fixed [error message] by [specific solution]"
   - Configuration discoveries: "[Setting/config] must be [requirement] because [reason]"
   - Workflow improvements: "Using [approach] instead of [old way] saves time/prevents errors"
   - Integration insights: "[Tool A] and [Tool B] interact in [unexpected way]"
   - Performance findings: "[Action] is slow/fast because [technical reason]"

2. If any insights found, suggest to user:
   "💡 Potential PROJECT_WISDOM.md entries:
   - [Specific suggestion based on session work]
   - [Another suggestion if applicable]
   Add these insights? (Y/n)"

3. If user agrees, update PROJECT_WISDOM.md:
   ### [Date]: [Topic/Technology - Specific Discovery]
   Insight: [The realization with specific details/errors]
   Impact: [How this changes future approach]
   Note: Title should contain searchable keywords

4. If PROJECT_WISDOM.md > 5KB:
   - Create PROJECT_WISDOM_ARCHIVE_[YYYYMMDD].md
   - Move older insights (keep last 10-15 active)
   - Add note after header: *Note: Older insights archived to PROJECT_WISDOM_ARCHIVE_[date].md*

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

After update:
1. Output: "Checkpoint saved to SESSION_CHECKPOINT_[HHMMSS].md and HANDOFF.md updated"
2. If any failed approaches encountered: "Failed approaches documented in checkpoint"
3. Suggest: "You can now run /compact to reduce context usage"
4. Remind: "Multiple checkpoints are preserved and will be merged by /wrap-session"