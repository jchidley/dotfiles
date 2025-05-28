# Checkpoint
Author: Jack Chidley
Created: 2025-05-25

Quick state capture and reflection during work. Maintains a lightweight HANDOFF.md in your project directory.

## When to Checkpoint

**Cognitive Milestones** (not time-based):
- ✅ Completed a meaningful chunk of work
- 💡 Discovered something important
- 🔄 About to switch focus/context
- 🤔 Feeling stuck or confused
- 📊 Context usage approaching 40%

## The 2-Minute Process

1. **Quick Reflection** (30 seconds)
   - What did I just accomplish/learn?
   - What surprised me?
   - What's the next logical step?

2. **Update Project HANDOFF.md** (90 seconds)
   
   Create/update `HANDOFF.md` in current project directory:
   ```markdown
   # Project: [Name]
   Updated: [Timestamp]
   
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
   
   ## Related Documents
   <!-- Auto-discovered by Claude when creating/updating -->
   - TODO.md - Active tasks
   - PROJECT_WISDOM.md - Technical insights
   - CLAUDE.md - Project-specific instructions
   - SESSION_*.md - Recent work logs
   ```

3. **Capture Breakthroughs** (if any)
   
   If you discovered something significant, append to `PROJECT_WISDOM.md`:
   - Check if PROJECT_WISDOM.md has hierarchical structure (Summary/Recent/Archives)
   - If hierarchical: append to "Active Insights" section
   - If simple file: append directly
   - Format:
   ```markdown
   ### [Date]: [Discovery]
   Insight: [The realization in one sentence]
   Impact: [Why this matters]
   ```
   - When PROJECT_WISDOM.md exceeds 5KB, migrate to hierarchical structure

## Why This Works

**For the LLM**:
- Always has current state in <300 tokens
- Can start any session with "Read HANDOFF.md"
- No stale context to confuse things
- Critical info front-loaded

**For You**:
- 2 minutes won't break flow
- Forces clarity about next step
- Captures insights while fresh
- Prevents "what was I doing?" moments

## The Key Question

"If I had amnesia in 1 hour, what would I need to know?"

That's what goes in HANDOFF.md. Everything else is noise.

## Implementation Notes for Claude

When creating/updating HANDOFF.md:
1. **Auto-discover related files** in the project directory
2. **Add "Related Documents" section** if any of these exist:
   - TODO.md → List as "TODO.md - Active tasks"
   - PROJECT_WISDOM.md → List as "PROJECT_WISDOM.md - Technical insights"
   - CLAUDE.md → List as "CLAUDE.md - Project-specific instructions"
   - SESSION_*.md → List most recent as "SESSION_XXX.md - Recent work log"
   - Other *.md files relevant to project
3. **Only list files that actually exist** - don't create placeholder entries
4. **Keep descriptions brief** - just enough to know what's in each file