# /req

## Purpose
Manage project requirements with automatic GitHub issue integration.

## Prerequisites  
- Project root directory from environment info
- REQUIREMENTS.md template at ~/.local/share/chezmoi/dot_claude/templates/REQUIREMENTS.md
- Reference: See references/github-operations.md for GitHub patterns
- Reference: See references/github-issue-template.md for issue template

## Process

Parse arguments: $ARGUMENTS
Change to project root directory before operations.

### Add New Requirement (default)
If arguments don't start with "list" or "status":

1. **Initialize REQUIREMENTS.md if needed**
   - Copy from template if doesn't exist
   - Replace placeholder text

2. **Check for duplicates**
   - Read existing requirements (skip Completed/Deprecated)
   - Check for: REQ-ID references, keyword matches, semantic similarity
   - If related found, offer to add as detail vs new requirement

3. **Generate requirement details**
   - Find next REQ-ID (REQ-0001 format)
   - Extract name from first 5-8 words
   - Generate 1-2 sentence rationale
   - Determine section (1.0 Foundation, 1.1 Enhancements, 2.0 Major Features)

4. **Add to REQUIREMENTS.md**
   ```markdown
   #### REQ-XXXX: [Name]
   - **Priority**: Medium
   - **Status**: Pending
   - **GitHub Issue**: Not created
   - **Description**: [User's description]
   - **Rationale**: [Generated]
   - **Implementation**: See GitHub issue for details
   ```

5. **Create GitHub issue (if in GitHub repo)**
   - Check auth status
   - Use template from references/github-issue-template.md
   - Update REQUIREMENTS.md with issue number

Output: Success message with REQ-ID and issue number (if created)

### List Requirements
If arguments = "list":

1. Check REQUIREMENTS.md exists
2. Extract all requirements with status
3. Format by version sections with summary counts

Output:
```
## Project Requirements

### Version 1.0 - Foundation
REQ-0001: [Name] - High priority - Implemented (#23)

### Summary
Total: X requirements
By Status: Implemented (X), In Progress (X), Pending (X)
```

### Check Status
If arguments = "status REQ-XXXX":

1. Validate REQ-ID format
2. Find requirement in REQUIREMENTS.md
3. Display full details

Output: Full requirement details with GitHub issue link

## Error Handling
- No arguments: Show usage
- Invalid REQ-ID: Show format example
- Missing REQUIREMENTS.md: Guide to create first requirement
- GitHub auth failed: Note issue not created, suggest /req-to-issue

## Examples

### Add requirement
```
/req Add user authentication with OAuth2 support
```

### List all
```
/req list  
```

### Check specific
```
/req status REQ-0001
```