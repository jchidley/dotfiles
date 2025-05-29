# /req - Requirements Management

**CLAUDE INSTRUCTION**: When the user invokes this command, YOU MUST execute the appropriate action below, not just display this documentation.

## Command Actions

When user types `/req <subcommand> [args]`, execute the following:

### `/req check <description>`
1. Analyze if the description is a PROJECT requirement (new feature/capability)
2. Respond with "✅ This IS a project requirement" or "❌ This is NOT a project requirement"
3. Provide reasoning for your decision

### `/req add <description>`
1. Check for existing REQUIREMENTS.md in current project:
   - First check: `./REQUIREMENTS.md` (current directory)
   - If not found: Create from template at `/home/jack/.local/share/chezmoi/dot_claude/templates/REQUIREMENTS.md`
2. Read the REQUIREMENTS.md file
3. Find the highest existing REQ number (or start at REQ-0001)
4. Create new requirement as REQ-XXXX (next sequential number, padded to 4 digits)
5. Add to appropriate version section with proper format:
   ```markdown
   #### REQ-XXXX: [Brief requirement name from description]
   - **Priority**: High/Medium/Low (ask user or infer)
   - **Status**: Pending
   - **GitHub Issue**: Not created
   - **Description**: [User's full description]
   - **Rationale**: [Ask user or infer from context]
   - **Implementation**: See GitHub issue for implementation details
   ```
6. Write the updated REQUIREMENTS.md back to the same location
7. Confirm: "✅ Added REQ-XXXX to REQUIREMENTS.md: <description>"
8. Remind: "Run `/req-to-issue REQ-XXXX` to create GitHub issue with detailed tracking"

### `/req list`
1. Check for REQUIREMENTS.md in current directory
2. If not found, inform user: "No REQUIREMENTS.md found in current directory"
3. Read all requirements from the file
4. Display in organized format:
   ```
   ## Requirements Summary
   
   ### Version 1.0 - Foundation
   REQ-0001: [Name] [Status: Pending/Implemented] [Issue: #123 or Not created]
   REQ-0002: [Name] [Status: Pending/Implemented] [Issue: #456 or Not created]
   
   ### Version 1.1 - Enhancements
   REQ-0010: [Name] [Status: Planned] [Issue: Not created]
   
   Total: X requirements (Y implemented, Z pending)
   ```

### `/req status <REQ-XXXX>`
1. Check for REQUIREMENTS.md in current directory
2. If not found, inform user: "No REQUIREMENTS.md found in current directory"
3. Find the specified requirement
4. Display full details:
   ```
   REQ-XXXX: [Name]
   Priority: High/Medium/Low
   Status: Pending/Implemented/Planned
   GitHub Issue: #123 or Not created
   Description: [Full description]
   Rationale: [Rationale]
   Dependencies: [If any]
   ```

## Process Reminder

This command helps ensure proper requirement tracking:

1. **Only for PROJECT requirements** - Features that define how software should work
2. **Not for regular tasks** - Bug fixes, explanations, debugging don't need requirements
3. **Creates REQ-XXXX entries** - Sequential numbering in REQUIREMENTS.md
4. **GitHub integration** - Use `/req-to-issue REQ-XXXX` after creating requirement

## Examples

### What IS a requirement:
- "The API should validate all inputs"
- "Users should be able to export data as CSV"
- "System should support multi-tenant architecture"

### What is NOT a requirement:
- "Fix the typo in README.md"
- "Explain how async/await works"
- "Debug this error message"
- "Update dependencies"

## Implementation

When you run `/req add`:
1. Checks next available REQ number
2. Adds to appropriate version section in REQUIREMENTS.md
3. Follows the standard format with Priority, Status, GitHub Issue, Description, Rationale
4. Reminds you to create GitHub issue with `/req-to-issue`

When you run `/req check`:
1. Analyzes if the description is a project requirement
2. Suggests whether to track it or just implement directly
3. Provides reasoning for the decision