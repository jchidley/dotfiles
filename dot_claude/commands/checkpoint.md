# /checkpoint

Captures work progress and raw wisdom discoveries into CURRENT_PROJECT_WISDOM.md for later refinement.

IMPORTANT: First use TodoRead tool to get current todo list before proceeding.
This ensures HANDOFF.md always has the most recent todo state for proper restoration.

IMPORTANT: Change to project root directory before file operations.
Use the working directory from the environment info as the project root.

Create SESSION_CHECKPOINT_[YYYYMMDD_HHMMSS].md (timestamped to support multiple checkpoints):

# Session Checkpoint [YYYYMMDD_HHMMSS]
Created: [Current timestamp]
Task: [One line description of current task]
Progress: [What's been done since last checkpoint - 1-2 lines max]
Next: [Immediate next action]

## Work Done
[List specific accomplishments since last checkpoint]

## Failed Approaches
[Any approaches that didn't work since last checkpoint]

Note: This file will be incorporated into final session log by /wrap-session

Update HANDOFF.md (at project root, same directory as PROJECT_WISDOM.md) with current timestamp:

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
- CLAUDE.md - Project instructions

Review session for wisdom capture to CURRENT_PROJECT_WISDOM.md:
IMPORTANT: CURRENT_PROJECT_WISDOM.md should be located at the project root (the initial working directory shown in environment info).
If it doesn't exist at project root, create it there - NOT in subdirectories or other locations.

1. Check for wisdom patterns using the triggers listed in wisdom-triggers.md:
   - Technical discoveries (tool usage, error solutions, configurations)
   - Conversation triggers ("we should always", "remember that", etc.)
   - Evolution patterns ("tried X, Y worked better", anti-patterns)

2. Use the prompting format from wisdom-triggers.md to suggest captured insights to the user.

3. If user agrees, append to CURRENT_PROJECT_WISDOM.md using the entry format from wisdom-triggers.md.

4. Note: CURRENT_PROJECT_WISDOM.md accumulates across sessions. Archive management handled by /clean-wisdom command.

After update:
1. Output: "Checkpoint saved to SESSION_CHECKPOINT_[YYYYMMDD_HHMMSS].md and HANDOFF.md updated"
2. If any failed approaches encountered: "Failed approaches documented in checkpoint"
3. Suggest: "You can now run /compact to reduce context usage"
4. Remind: "Multiple checkpoints are preserved and will be merged by /wrap-session"