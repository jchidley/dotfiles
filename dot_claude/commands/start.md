# /start - Begin or Continue Work Session
Author: Jack Chidley
Created: 2025-05-25

Start a new session or continue previous work with proper context loading.

## Usage Examples

```bash
# Continue a project with handoff
/start zwift-race-finder

# Start fresh project work
/start new-project-name

# Resume without specific project
/start
```

## What This Command Does

1. **Auto-discovers key project files** in priority order:
   - HANDOFF.md - Current work state and next steps
   - TODO.md - Active tasks and priorities
   - PROJECT_WISDOM.md - Accumulated knowledge
   - CLAUDE.md - Project-specific instructions
   - README.md - General project overview
   - Recent logs (SESSION_*.md) if complex history needed

2. **For Continued Work**:
   - Loads HANDOFF.md as primary working memory
   - Checks TODO.md for active tasks and priorities
   - Reviews recent git commits for context
   - References PROJECT_WISDOM.md if technical details needed
   - Only loads logs if HANDOFF references them
   - Identifies metrics, completion percentages, or test status
   - Picks up exactly where last session ended

3. **For New Work**:
   - Creates initial HANDOFF.md structure
   - Checks for existing README.md or CLAUDE.md
   - Establishes working memory for session
   - Ready for checkpoint/wrap workflow

## The Process

### Continuing Previous Work
1. "I'll continue from the previous session"
2. Auto-discover and read key files:
   - Always: HANDOFF.md (primary context)
   - If exists: TODO.md (check active tasks)
   - If referenced: PROJECT_WISDOM.md, logs, etc.
3. "Ready to proceed with: [specific next task from TODO.md or HANDOFF.md]"

### Starting New Work
1. "Starting new work session"
2. Check for existing project files:
   - README.md - understand project basics
   - CLAUDE.md - check for special instructions
3. Create HANDOFF.md with initial structure
4. "What would you like to work on?"

## Why This Works

- **Fast Start**: HANDOFF.md has everything needed to resume
- **Progressive Loading**: Only load logs if truly needed
- **Clear Intent**: Explicitly states continuation vs new work
- **Working Memory**: Maintains context across sessions

## Integration with Workflow

```
/start → work → /checkpoint → work → /wrap-session
  ↑                                         ↓
  └─────────── Next Session ←───────────────┘
```

## Implementation Instructions for Claude

When user runs `/start`:

1. **File Discovery Phase**:
   ```bash
   # Check git state first
   - Run git branch --show-current → Confirm working branch
   - Run git status → Check for uncommitted changes
   - Run git log --oneline -5 → Recent commits
   
   # Then check for key files in this order
   - If HANDOFF.md exists → Read it (primary context)
   - If TODO.md exists → Read it (active tasks)
   - If plan.md exists → Note strategic direction
   - If PROJECT_WISDOM.md exists → Note its presence (read only if needed)
   - If CLAUDE.md exists → Read it (project instructions)
   - If README.md exists → Scan it briefly (project overview)
   ```

2. **Context Loading**:
   - HANDOFF.md is always primary - contains immediate next steps
   - TODO.md shows all active tasks - mention any high priority items
   - Only deep-read other files if HANDOFF references them
   - Keep initial response focused on immediate next action

3. **Response Format for Continuing Work**:
   ```
   ## Project: [Name]
   Branch: [current branch]
   Current Status: [Brief status from HANDOFF.md]
   Uncommitted Changes: [Yes/No - brief summary if yes]
   
   Recent Progress:
   - [Last commit or accomplishment]
   - [Key metric if applicable]
   
   Next Actions:
   1. [Primary task from HANDOFF.md]
   2. [High priority from TODO.md if exists]
   
   Ready to proceed with: [specific next task]
   ```
   
4. **Response Format for New Work**:
   ```
   Starting new work session for [project name].
   
   [Brief project description from README if exists]
   
   What would you like to work on?
   ```

## Tips

- Run from project directory for auto-detection
- HANDOFF.md is your working memory between sessions
- Use /checkpoint regularly during work
- End with /wrap-session to prepare for next time
- Key files are auto-discovered, no need to specify them