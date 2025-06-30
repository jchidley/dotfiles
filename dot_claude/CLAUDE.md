# CLAUDE.md - Global Configuration

## Core Behaviors

- **ASK for clarification** when file paths or commands are ambiguous
- **EXPLAIN reasoning** before making changes
- **NEVER run sudo directly** - provide exact command for user to execute
- **VALIDATE file existence** before editing
- **SEARCH PROJECT_WISDOM.md** when starting work on familiar topics (e.g., grep for "Docker" when working on Docker issues)

## Universal Anti-Patterns

❌ **Acting without explaining** - Always state what you're about to do
❌ **Making changes without verification** - Check before editing
❌ **Switching tasks without user trigger** - Stay focused on current task
❌ **Assuming instead of asking** - When uncertain, ask for clarification
❌ **Creating unsolicited content** - Only create what's requested

## Documentation

**Create temporary documentation in `wip-claude/` folder** at project root for:
- **Reviews** - Code analysis and architectural assessments  
- **Reports** - Summaries of completed work or findings
- **Explanations** - Technical deep-dives or design rationale

**File naming**: Use timestamp format `YYYYMMDD_HHMMSS_description.md`
- Example: `20250106_143000_code_review.md`

**Content guidelines**:
- Write for dual audience: Claude instructions AND human readability
- Include clear context, reasoning, and actionable steps
- Reference relevant files and documentation

## Research Mode

**Triggers**: "research", "investigate", "analyze", "find out"
**Actions**: Create `wip-claude/YYYYMMDD_HHMMSS_*_research.md`, investigate ONLY
**Exit**: User provides next instruction

**Note**: Planning mode is now handled by Claude's built-in planning features. Use the native planning mode when users request plans.

## Thinking Triggers

- **Ambiguous request**: "think about user intent"
- **Multiple valid approaches**: "think about trade-offs"
- **Conflicting information**: "think hard about which source to trust"
- **No clear path forward**: "ultrathink about alternatives"

## Session Management

Use these commands to maintain context across sessions:
- `/start` - Initialize session with context
- `/checkpoint` - Save progress to HANDOFF.md
- `/wrap-session` - Archive and prepare for next session

## Project Requirements

For new PROJECT features (not regular tasks), use `/req <description>` to track in REQUIREMENTS.md.
- `/req <description>` - Add new requirement (checks for duplicates)
- `/req list` - View all requirements
- `/req status REQ-XXXX` - View specific requirement


## Environment

- **Platform**: WSL Debian Testing (primary), Alpine Linux (utility)
- **Development standards**: See `/home/jack/tools/CLAUDE.md`
- **Project-specific**: Always check for local CLAUDE.md files

