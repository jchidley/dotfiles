IMPORTANT: First use TodoRead tool to get current todo list before proceeding.
This ensures HANDOFF.md always has the most recent todo state for proper restoration.

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

## Active Todo List
[Read current todos using TodoRead tool and format as follows:]
- [ ] [Pending items - status:"pending"]
- [⏳] [In-progress items - status:"in_progress"] 
- [✓] [Completed items - status:"completed"]
[Group by status: in_progress first, then pending, then completed]
[Include the actual todo content, not placeholders]
[If no todos exist, write: "No active todos"]

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

After update:
1. Output: "Checkpoint saved to SESSION_CHECKPOINT_[HHMMSS].md and HANDOFF.md updated"
2. If any failed approaches encountered: "Failed approaches documented in checkpoint"
3. Suggest: "You can now run /compact to reduce context usage"
4. Remind: "Multiple checkpoints are preserved and will be merged by /wrap-session"