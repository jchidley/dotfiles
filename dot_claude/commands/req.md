# /req - Requirements Management

Manage project requirements following the structured process defined in CLAUDE.md.

## Usage
```
/req check <description>    # Check if something qualifies as a project requirement
/req add <description>      # Add a new project requirement to REQUIREMENTS.md
/req list                   # List all current requirements
/req status <REQ-XXXX>      # Check status of a specific requirement
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