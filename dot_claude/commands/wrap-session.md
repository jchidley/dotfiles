# /wrap-session

Finalizes session work and captures raw wisdom discoveries into CURRENT_PROJECT_WISDOM.md for later refinement.

IMPORTANT: Use TodoRead tool early to capture current todo state before wrapping up.
This ensures the final todo state is preserved accurately for the next session.
The todo list in HANDOFF.md will be used by /start to restore/merge todos.

IMPORTANT: Change to project root directory before file operations.
Use the working directory from the environment info as the project root.

Create sessions directory if it doesn't exist:
- Check if sessions/ directory exists
- If not, create it with: mkdir -p sessions

Check for SESSION_*.md files in root:
- Look for any SESSION_*.md files (could be multiple checkpoints)
- Sort them by timestamp to maintain chronological order
- Read their content to incorporate into the final session log

Create sessions/SESSION_[YYYYMMDD]_[HHMMSS].md:

# Session [YYYYMMDD]_[HHMMSS]
Project: [Name]

## Work Done
[If SESSION_*.md files exist, incorporate their "Work Done" sections in chronological order]
[And list what was actually accomplished since the last checkpoint - focus on completions]

## Failed Approaches
[Combine any "Failed Approaches" from checkpoint files]
[Add any new failed approaches since last checkpoint]

## Commits
[git log --oneline output for this session]

Clean up checkpoints after using them:
- Move all SESSION_*.md files to sessions/ directory after incorporating their content

Update HANDOFF.md:
- Refresh "Current State" with final status
- Update "Latest" with session's main achievement
- Include "Active Todo List" section:
  1. Use TodoRead tool to get current todo list
  2. Format todos with status indicators:
     - [ ] for pending items
     - [⏳] for in_progress items  
     - [✓] for completed items
  3. Group by status: in_progress first, then pending, then completed
  4. Include actual todo content under "## Active Todo List" section
  5. If no todos exist, write "No active todos"
- Ensure "Next Step" is current for next session (consider pending REQUIREMENTS.md items)
- Clear "If Blocked" if resolved

Check for uncommitted changes:
- Run git status
- If changes exist, remind: "Uncommitted changes detected. Consider committing before ending session."

Review session for wisdom capture to CURRENT_PROJECT_WISDOM.md:
IMPORTANT: CURRENT_PROJECT_WISDOM.md should be at the project root (initial working directory from environment info).
Check for CURRENT_PROJECT_WISDOM.md at project root first. If it doesn't exist, create it there - NOT in subdirectories.

1. Check session log and work done for wisdom patterns:
   a. Look for explicit "Technical Insights" section in the session file (if present)
   b. Apply triggers from wisdom-triggers.md to all content:
      - Technical discoveries (tool usage, error solutions, configurations)
      - Conversation triggers ("we should always", "remember that", etc.)
      - Evolution patterns ("tried X, Y worked better", anti-patterns)

2. Use the prompting format from wisdom-triggers.md to suggest captured insights to the user.
   Include any insights found in Technical Insights sections.

3. If user agrees, append to CURRENT_PROJECT_WISDOM.md using the entry format from wisdom-triggers.md.

4. Note: CURRENT_PROJECT_WISDOM.md accumulates across sessions. Archive management handled by /clean-wisdom command.

Verify cleanup:
- Confirm all SESSION_*.md files have been moved to sessions/
- If any remain in root, notify user

Tool Permission Management:
1. Track all tool permission requests during this session:
   - Check for tools that were granted permission (you used them)
   - Check for tools that were denied permission (you were blocked)
   - Create a list of new permissions not in .claude/settings.local.json

2. If new permissions found, prompt user:
   "🔧 Tool Permission Update Required
   
   The following tools were used during this session:
   
   ✅ ALLOWED (will be added to allow list):
   - Bash(git status:*)
   - WebFetch(domain:api.example.com)
   
   ❌ DENIED (will be added to deny list):
   - WebFetch(domain:suspicious-site.com)
   
   Do you want to:
   [A] Accept all changes
   [M] Modify selections
   [S] Skip permission updates
   
   Your choice: "

3. If user chooses [M], show each permission individually:
   "Bash(git status:*) - Currently: ALLOWED
   [K] Keep as allowed
   [D] Change to denied
   [S] Skip (don't add to either list)
   Your choice: "

4. Update .claude/settings.local.json based on user choices:
   - Add new allowed permissions to "allow" array
   - Add new denied permissions to "deny" array
   - Preserve existing permissions
   - Ensure no duplicates
   - Reference: https://docs.anthropic.com/en/docs/claude-code/settings

Output:
"Session logged to sessions/SESSION_[timestamp].md
Next: [from updated HANDOFF]
Ready for /clear

💭 Next session: If working on similar tasks, remind Claude to check history"