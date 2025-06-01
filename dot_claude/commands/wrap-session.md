Create sessions directory if it doesn't exist:
- Check if sessions/ directory exists
- If not, create it with: mkdir -p sessions

Clean up checkpoint:
- Delete SESSION_CHECKPOINT.md if exists

Create sessions/SESSION_[YYYYMMDD]_[HHMMSS].md:

# Session [YYYYMMDD]_[HHMMSS]
Project: [Name]

## Work Done
[List what was actually accomplished - focus on completions]

## Failed Approaches
[Only if any - what didn't work and why]

## Commits
[git log --oneline output for this session]

Update HANDOFF.md:
- Refresh "Current State" with final status
- Update "Latest" with session's main achievement
- Ensure "Next Step" is current for next session (consider pending REQUIREMENTS.md items)
- Clear "If Blocked" if resolved

Check for uncommitted changes:
- Run git status
- If changes exist, remind: "Uncommitted changes detected. Consider committing before ending session."

Check and archive PROJECT_WISDOM.md if > 5KB:
1. If PROJECT_WISDOM.md exists and > 5KB:
   - Create PROJECT_WISDOM_ARCHIVE_[date].md
   - Move older insights (keep last 10-15 active)
   - Update PROJECT_WISDOM.md header with archive reference
2. If not exists but session had discoveries, create with:
   # Project Wisdom
   
   Insights and lessons learned from development.
   
   ## Active Insights

Check for cleanup:
- If SESSION_*.md files exist in root: "Run 'mv SESSION_*.md sessions/' to organize"

Output:
"Session logged to sessions/SESSION_[timestamp].md
Next: [from updated HANDOFF]
Ready for /clear

💭 Next session: If working on similar tasks, remind Claude to check history"