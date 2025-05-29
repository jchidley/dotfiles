Create SESSION_[YYYYMMDD]_[HHMMSS].md:

# Session Log: [Project Name]
Date: [Current date]
Duration: [Estimate based on work]

## Summary
[2-3 sentences of what was accomplished]

## Key Accomplishments
- [Specific achievement 1]
- [Specific achievement 2]
- [Specific achievement 3]

## Technical Insights
[Any important discoveries or learnings]

## Failed Approaches & Dead Ends
[Document approaches that didn't work to save time in future sessions]
- [Failed approach]: [Why it failed and what was learned]
- [Dead end]: [Technical reason or error that made this unviable]
(Be specific about error messages, incompatibilities, or design flaws)

## Challenges Encountered
[Any blockers or difficulties faced]

## Files Modified
[List main files changed]

## Next Session Priority
[What should be tackled first next time]
[Check REQUIREMENTS.md for high-priority pending items]

## Git Activity
[List commits made during session]

Update HANDOFF.md:
- Refresh "Current State" with final status
- Update "Latest" with session's main achievement
- Ensure "Next Step" is current for next session (consider pending REQUIREMENTS.md items)
- Clear "If Blocked" if resolved

Check for uncommitted changes:
- Run git status
- If changes exist, remind: "Uncommitted changes detected. Consider committing before ending session."

Archive wisdom if PROJECT_WISDOM.md > 5KB:
1. Create PROJECT_WISDOM_ARCHIVE_[date].md
2. Move older insights to archive
3. Keep only recent/active insights in main file

Final output:
"Session wrapped. Key accomplishments: [brief summary]
Next session should start with: [next step from HANDOFF]"