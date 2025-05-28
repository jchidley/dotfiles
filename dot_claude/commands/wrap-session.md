# Wrap Session
Author: Jack Chidley
Created: 2025-05-25

End-of-session workflow that leverages your checkpoint work. Moves HANDOFF.md content to permanent docs and prepares for next session.

## Prerequisites

- Should have been using `/checkpoint` during session
- HANDOFF.md should be current
- Ready to end work on this topic/project

## The Process

1. **Check HANDOFF.md Status**
   - Verify HANDOFF.md exists and is current
   - If not, do a quick checkpoint first
   - Review what the session accomplished
   - Run `git status` to check for uncommitted changes
   - Run `git log --oneline -10` to capture session's commits

2. **Move to Permanent Documentation**
   
   Based on HANDOFF.md content, update:
   - **todo.md**: Move completed items, add new tasks discovered
   - **plan.md**: Update status section if significant progress made
   - **README.md**: Only if major feature/metric changed
   
   For significant discoveries from PROJECT_WISDOM.md:
   - Add detailed entry to appropriate *_LOG.md file
   - Include context, technical details, and impact

3. **Check Tools Used During Session**
   
   Review which tools were used during this session and check against settings.local.json:
   - Create a list of all tools used (Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS, etc.)
   - Check if project has `.claude/settings.local.json` or if one should be created
   - If settings file exists, verify all used tools are in the enabled list
   - If tools are missing, prompt user with suggested additions
   
   Example prompt:
   ```
   ## Tools Used This Session
   
   During this session, I used these tools:
   - Read (for reading files)
   - Edit (for modifying existing files)
   - Bash (for running commands)
   - Grep (for searching content)
   
   Your current .claude/settings.local.json may need these tools added:
   {
     "tools": {
       "enabled": [
         "Read",
         "Edit", 
         "Bash",
         "Grep"
       ]
     }
   }
   ```

4. **Create Session Log Entry**
   
   Find or create appropriate *_LOG.md file:
   - Search for existing topic-specific *_LOG.md files
   - For new topics: create TOPIC_LOG.md (e.g., WATCHFACE_LOG.md, API_INTEGRATION_LOG.md)
   - Use PROJECT_LOG.md only for general/miscellaneous items
   
   Add session entry:
   ```markdown
   ## Session [Date]: [Brief Title]
   
   [Expand on HANDOFF.md with more detail]
   
   ### Key Accomplishments
   - [What got done]
   
   ### Git Activity
   ```
   [Include output of git log --oneline -10 if commits were made]
   [Include summary of git status if uncommitted changes exist]
   ```
   
   ### Discoveries
   - [Any breakthroughs - pull from PROJECT_WISDOM.md]
   - [Technical challenges and solutions]
   
   ### Technical Details
   - [Implementation notes, code snippets, etc.]
   - [What worked and what didn't]
   
   ### Next Session Priority
   - [From HANDOFF.md next step]
   ```
   
   Update or create Key Commands section at bottom of log:
   ```markdown
   ---
   ## Key Commands
   
   ```bash
   # [Description of what commands do]
   command --with-args
   
   # [Another useful command]
   another-command --options
   ```
   ```

5. **Prepare for Next Session**
   
   Create final message:
   ```
   ## Session Complete
   
   Project: [Name]
   Progress: [Current state from HANDOFF.md]
   Next Priority: [The one thing from HANDOFF.md]
   
   Ready to compact! 
   
   To continue next session:
   1. Start with: "Continue [project]. Read HANDOFF.md"
   2. Or for full context: "Continue [project]. Read HANDOFF.md and latest log entry"
   ```

6. **Update HANDOFF.md for Next Session**
   - Keep essential context and next steps
   - Ensure "Related Documents" section lists all key files:
     * TODO.md (if exists)
     * PROJECT_WISDOM.md (if exists)
     * CLAUDE.md (if exists)
     * Latest SESSION_*.md file
   - This helps /start command load complete context

## Why This Works

- **Leverages checkpoint work**: No duplicate effort
- **Progressive detail**: HANDOFF → Logs → Full docs
- **Clean handoffs**: Next session starts with clear state
- **Maintains history**: Logs capture journey, not just destination

## The Key Principle

HANDOFF.md is your working memory.
Logs are your long-term memory.
This command moves one to the other.

## Implementation Notes for Claude

When finalizing HANDOFF.md:
1. **Always include "Related Documents" section** at the end
2. **Auto-discover files** in the project directory:
   - Check for TODO.md, PROJECT_WISDOM.md, CLAUDE.md
   - Find most recent SESSION_*.md file
   - Include other relevant *.md files (plan.md, issues.md, etc.)
3. **Format consistently**:
   ```markdown
   ## Related Documents
   - TODO.md - Active tasks
   - PROJECT_WISDOM.md - Technical insights  
   - SESSION_003_20250526.md - Latest work log
   ```
4. This ensures /start command can discover all context files

## Git Reminder

Before wrapping up the session, ensure all changes are pushed:
```bash
git push
```
This ensures your work is backed up and available for the next session.