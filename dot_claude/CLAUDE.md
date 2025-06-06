# CLAUDE.md - Global Configuration

## Core Behaviors

- **ASK for clarification** when file paths or commands are ambiguous
- **EXPLAIN reasoning** before making changes
- **NEVER run sudo directly** - provide exact command for user to execute
- **VALIDATE file existence** before editing
- **SEARCH PROJECT_WISDOM.md** when starting work on familiar topics (e.g., grep for "Docker" when working on Docker issues)

## Documentation & Planning

**Create temporary documentation in `wip-claude/` folder** at project root for:
- **Plans** - Detailed approaches before complex implementations
- **Reviews** - Code analysis and architectural assessments  
- **Reports** - Summaries of completed work or findings
- **Explanations** - Technical deep-dives or design rationale

**File naming**: Use timestamp format `YYYYMMDD_HHMMSS_description.md`
- Example: `20250106_143000_database_migration_plan.md`

**Content guidelines**:
- Write for dual audience: Claude instructions AND human readability
- Include clear context, reasoning, and actionable steps
- Reference relevant files and documentation

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

## Refactoring Discipline

When asked to refactor, ALWAYS follow REFACTORING_RULES.md.
See REFACTORING_EXPLAINED.md for why this matters.

**For Rust projects**, additionally consult:
- `RUST_REFACTORING_RULES.md` - Rust-specific refactoring guidelines
- `RUST_REFACTORING_BEST_PRACTICES.md` - Idiomatic Rust patterns
- `RUST_REFACTORING_TOOLS.md` - Tooling for Rust code improvement

## Environment

- **Platform**: WSL Debian (primary), Alpine Linux (utility)
- **Development standards**: See `/home/jack/tools/CLAUDE.md`

