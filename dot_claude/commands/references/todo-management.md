# Todo Management Reference

Common patterns for todo list parsing and management.

## Markdown Checkbox Parsing

### Status Mapping
```
[ ] → pending
[⏳] → in_progress  
[✓] → completed
```

### Parse Pattern
```markdown
## Active Todo List
- [ ] Pending task description
- [⏳] In progress task description
- [✓] Completed task description
```

## Todo Merge Logic

### Merge Algorithm
1. Read current todos using TodoRead
2. Parse new todos from markdown source
3. For each new todo:
   - Check if content already exists in current list
   - If not exists: add with status from source
   - If exists with different status: keep MORE ADVANCED status
   - Status hierarchy: completed > in_progress > pending
4. Never duplicate todos by content
5. Preserve all current todos even if not in source

### Example Implementation
```
For each source todo:
  found = false
  for each current todo:
    if source.content == current.content:
      found = true
      if source.status > current.status:
        current.status = source.status
      break
  if not found:
    add source todo to current list
```

## CHECKPOINT.md Format
```markdown
# CHECKPOINT
Created: YYYY-MM-DD HH:MM

## Latest Achievement
[One-line summary of most recent completed work]

## Todos
- [ ] Pending task
- [⏳] In progress task
- [✓] Completed task

## Notes
[Any important context for resuming work]
```

## Usage in Commands

### Creating Checkpoint (/checkpoint)
1. Use TodoRead to get current state
2. Format as markdown checkboxes
3. Save with timestamp and latest achievement

### Restoring from Checkpoint (/start)
1. Check if CHECKPOINT.md exists
2. Parse todos from "## Todos" section
3. Merge with current todo list
4. Delete CHECKPOINT.md after successful merge

### Session Wrapping (/wrap-session)
1. Create CHECKPOINT.md first (safety net)
2. Include todos in session document
3. Update HANDOFF.md with todo state