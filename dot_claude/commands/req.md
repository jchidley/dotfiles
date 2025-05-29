# /req - Requirements Management

**CLAUDE INSTRUCTION**: When the user invokes this command, YOU MUST execute the appropriate action below, not just display this documentation.

## Command Actions

When user types `/req <subcommand> [args]`, execute the following:

### `/req check <description>`
1. Analyze if the description is a PROJECT requirement (new feature/capability)
2. Respond with "✅ This IS a project requirement" or "❌ This is NOT a project requirement"
3. Provide reasoning for your decision

### `/req add <description>`
1. Read `/home/jack/.local/share/chezmoi/dot_claude/templates/REQUIREMENTS.md`
2. Find the highest existing REQ number
3. Create new requirement as REQ-XXXX (next sequential number)
4. Add to appropriate version section with proper format
5. Confirm addition with "✅ Added REQ-XXXX: <description>"

### `/req list`
1. Read REQUIREMENTS.md
2. Display all requirements with their status
3. Format: "REQ-XXXX: <name> [<status>]"

### `/req status <REQ-XXXX>`
1. Find the specified requirement in REQUIREMENTS.md
2. Display its full details

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