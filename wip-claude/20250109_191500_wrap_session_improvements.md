# Wrap-Session Command Improvements
Created: 2025-01-09 19:15

## Purpose
Improve /wrap-session to track key documents and provide clear reload instructions after /clear.

## Current Gaps
1. Doesn't track key working documents created during session
2. Doesn't tell user which documents to reload after /clear
3. Session log doesn't include "Key Documents" section
4. HANDOFF.md doesn't have reload guidance

## Proposed Changes

### 1. Add to Session Log (STEP 4)
Add new section after "Work Done":
```markdown
## Key Documents
[List of important documents created/modified with brief description]
- wip-claude/20250109_183000_claude_hooks_comprehensive_plan.md - Implementation roadmap
- wip-claude/20250109_185000_tools_claude_md_cleaned.md - Ready to replace tools/CLAUDE.md
```

### 2. Add to HANDOFF.md (STEP 6)
Add new section before "Related Documents":
```markdown
## Context Reload After Clear
Essential documents for continuing work:
1. HANDOFF.md - This file (project state and todos)
2. [Key working document 1] - [Purpose]
3. [Key working document 2] - [Purpose]
```

### 3. Track Document Creation During Session
Add logic to track when Write tool creates important documents:
- Documents in wip-claude/ with timestamps
- Documents mentioned in todos
- Documents referenced in commit messages

### 4. Enhanced Output Message
Change final output to:
```
Session logged to sessions/SESSION_[timestamp].md
HANDOFF.md updated with current state
Next: [from updated HANDOFF]

📋 To continue after /clear, reload:
1. HANDOFF.md (project state)
2. [Key document 1]
3. [Key document 2]

Ready for /clear or /compact
```

## Implementation Steps

### STEP 3.5: Track Key Documents (new step)
```markdown
Track key documents created/modified:
- Check for new wip-claude/*.md files created this session
- Note any documents mentioned in completed todos
- Include documents that represent deliverables or plans
```

### Modified STEP 4: Session Log with Key Documents
```markdown
Create sessions/SESSION_[YYYYMMDD]_[HHMMSS].md:

# Session [YYYYMMDD]_[HHMMSS]
Project: [Name]

## Work Done
[Main accomplishments from todos + git commits]

## Key Documents
[Important files created/modified with descriptions]

## Commits
[git log output captured earlier]

## Active Todos
[Copy from CHECKPOINT.md]
```

### Modified STEP 6: HANDOFF with Reload Section
```markdown
Update HANDOFF.md with:
- Current timestamp
- Latest achievement from checkpoint
- Active todo list from checkpoint
- Refresh Current State and Next Step
- NEW: Context Reload section listing essential documents
```

### Modified Output:
```markdown
Output:
"Session logged to sessions/SESSION_[timestamp].md
HANDOFF.md updated with current state
Next: [from updated HANDOFF]

📋 To continue after /clear, reload:
1. HANDOFF.md (project state)
2. [Key document from Context Reload section]
3. [Additional key documents as needed]

Ready for /clear or /compact"
```

## Benefits

1. **Clear Restart Path**: User knows exactly what to load after /clear
2. **Document Tracking**: Important work products are cataloged
3. **Reduced Context Loss**: Minimal set of documents provides full context
4. **Better Handoffs**: Future sessions can quickly identify key references

## Example Output

After implementing these changes, wrap-session would output:
```
Session logged to sessions/SESSION_20250109_191500.md
HANDOFF.md updated with current state
Next: Implement Phase 1 claude-hooks: file existence, Python 3.12 enforcement

📋 To continue after /clear, reload:
1. HANDOFF.md (project state)
2. wip-claude/20250109_183000_claude_hooks_comprehensive_plan.md (implementation roadmap)
3. wip-claude/20250109_185000_tools_claude_md_cleaned.md (ready to replace tools/CLAUDE.md)

Ready for /clear or /compact
```

This ensures smooth session continuity with minimal context reload.