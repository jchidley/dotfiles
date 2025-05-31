# Session Management Workflow

Minimal state management for infinite context length through strategic file usage.

## Command Flow

```
/start → work → /checkpoint → /compact → /start → work → /wrap-session → /clear
```

## File Purposes (No Duplication)

- **HANDOFF.md** - Project state (cross-session)
- **SESSION_CHECKPOINT.md** - Current task only (mid-session)  
- **sessions/SESSION_*.md** - Historical archive (read by humans)

## Commands

### `/start`
Reads: HANDOFF.md, SESSION_CHECKPOINT.md (if exists), TODO.md, CLAUDE.md
Shows: Current project status and immediate focus

### `/checkpoint`  
- Updates HANDOFF.md with project state
- Creates minimal SESSION_CHECKPOINT.md (task/progress/next)
- Enables `/compact` without losing context

### `/compact`
Built-in Claude command - clears conversation, keeps files

### `/wrap-session`
- Archives session to sessions/SESSION_[timestamp].md
- Updates HANDOFF.md for next session
- Deletes SESSION_CHECKPOINT.md
- Ready for `/clear`

### `/clear`
Built-in Claude command - full reset

## Example Workflow

```bash
/start                    # Load project state
# ... work ...
/checkpoint              # Save progress
/compact                 # Clear conversation
/start                   # Resume from checkpoint
# ... work more ...
/wrap-session           # Archive session
/clear                  # Fresh start
```

## Key Points

- Each file has ONE purpose - no duplication
- SESSION_CHECKPOINT.md is minimal and temporary
- HANDOFF.md is the source of truth for project state
- Session archives are for human review, not Claude context