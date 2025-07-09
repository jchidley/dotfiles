# Session Document Coordination Fix
Created: 2025-07-09 12:13

## Issue Identified

The /wrap-session and /start commands don't coordinate document management effectively:

1. **Document Creation Not Reported**: Step 6 creates key documents but doesn't report what was created
2. **Context Reload Not Used**: HANDOFF.md has "Context Reload After Clear" but /start doesn't use it
3. **Manual Maintenance**: The context reload list is manually maintained, not automated

## Current Problems

### In /wrap-session:
- Creates HANDOFF.md, CURRENT_PROJECT_WISDOM.md, WORKING_WITH_CLAUDE.md silently
- User doesn't know what was newly created
- "Context Reload After Clear" section is static, not dynamically updated

### In /start:
- Doesn't read or use the "Context Reload After Clear" section
- Doesn't suggest which documents to reload
- Misses opportunity to restore full context

## Proposed Solution

### 1. Enhanced /wrap-session (Already Updated)
- Track which documents are created in Step 6
- Echo creation of each document to user
- Automatically update "Context Reload After Clear" with:
  - Most recent wip-claude document
  - PROJECT_WISDOM.md if exists
  - CURRENT_PROJECT_WISDOM.md if has substantial content
  - Other key files based on session work

### 2. Enhanced /start (Needs Update)
Add new step after reading HANDOFF.md:
```
STEP X: Check context reload suggestions
- Read "Context Reload After Clear" section from HANDOFF.md
- For each document listed:
  - Check if it exists
  - If exists, note for potential reload
- Output: "📚 Key documents from last session:"
  - List each available document with purpose
- Ask: "Would you like me to reload key context? (y/n)"
- If yes, read top 2-3 most relevant documents
```

### 3. Integration Benefits
- Seamless context restoration between sessions
- User awareness of what documents exist and why
- Automatic maintenance of context reload list
- No lost work or forgotten documents

## Implementation Priority

1. ✅ /wrap-session Step 6 - Report created documents
2. ✅ /wrap-session Step 7 - Auto-update context reload list  
3. ⏳ /start - Add context reload step
4. ⏳ Test full workflow: wrap → clear → start

## Example Flow

### End of Session (/wrap-session):
```
✨ Created WORKING_WITH_CLAUDE.md symlink to global version
📄 Created 1 key document this session

[Updates HANDOFF.md with dynamic context reload list]

📚 Key Documents Available:
  ✓ HANDOFF.md - Project state and todos
  ✓ wip-claude/20250110_001500_core_pattern_hooks_implemented.md - Latest work
  ✓ PROJECT_WISDOM.md - Distilled patterns
```

### Start of Next Session (/start):
```
## Project: Chezmoi Dotfiles
Status: CORE pattern hooks implemented
Branch: main | Changes: No

📚 Key documents from last session:
1. wip-claude/20250110_001500_core_pattern_hooks_implemented.md - CORE pattern implementation
2. PROJECT_WISDOM.md - Distilled patterns (4 CORE, 4 established)

Would you like me to reload key context? (y/n)
```

This creates a complete loop where document creation, tracking, and restoration are coordinated.