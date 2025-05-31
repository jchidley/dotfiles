Create SESSION_CHECKPOINT.md (single file, overwritten each checkpoint):

# Session Checkpoint
Task: [One line description of current task]
Progress: [What's been done THIS SESSION - 1-2 lines max]
Next: [Immediate next action]

Note: This file is temporary and only for post-/compact restoration

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

If significant discovery occurred:
1. Check if PROJECT_WISDOM.md exists
2. If exists and has hierarchical structure, append to "Active Insights"
3. If exists as simple file, append directly
4. Format:
   ### [Date]: [Discovery]
   Insight: [The realization in one sentence]
   Impact: [Why this matters]
5. If PROJECT_WISDOM.md > 5KB, suggest migrating to hierarchical structure

After update:
1. Output: "Checkpoint saved. Progress backed up to HANDOFF.md and SESSION_CHECKPOINT.md"
2. If any failed approaches encountered: "Remember to document what didn't work in HANDOFF.md"
3. Suggest: "You can now run /compact to reduce context usage"