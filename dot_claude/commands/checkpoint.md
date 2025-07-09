# /checkpoint

Minimal context safety net - saves current todos and latest achievement for recovery.
Use when context is getting full but you need to continue working.

IMPORTANT: First use TodoRead tool to get current todo list.

cd <working directory from environment info>

First get timestamp: `TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")`

Write CHECKPOINT.md (overwrites if exists):

# Checkpoint
Created: ${TIMESTAMP}
Latest: [One line - most recent accomplishment or current focus]

## Todos
[Write the full todo list from TodoRead in markdown format]
- [ ] = pending
- [⏳] = in_progress  
- [✓] = completed

Output: "Checkpoint saved. Run /compact if needed to continue working."

Note: CHECKPOINT.md is temporary and will be:
- Used by /start if session ends unexpectedly
- Cleaned up automatically by /start or /wrap-session
- Overwritten by next /checkpoint (most recent wins)