# Create GitHub Issue from Requirement

This command creates a GitHub issue from a requirement in REQUIREMENTS.md.

## Instructions

1. Extract the requirement details from REQUIREMENTS.md for the specified REQ number
2. Create a GitHub issue with:
   - Title: `[REQ-XXXX] Requirement Name`
   - Labels: `requirement`, priority level (high/medium/low)
   - Body containing:
     - Description from REQUIREMENTS.md
     - Rationale
     - Dependencies (if any)
     - Implementation Details section with:
       - Design decisions
       - Code examples
       - Technical notes
       - Progress updates
     - Testing section
     - Link back to REQUIREMENTS.md

3. Update REQUIREMENTS.md to include the GitHub issue number
4. Output the created issue URL

## Example Usage

When called with: `/req-to-issue REQ-0001`

Creates issue like:
```
Title: [REQ-0001] Automatic Requirement Tracking
Labels: requirement, high-priority

## Description
Every request should check if it's a new requirement and add to REQUIREMENTS.md

## Rationale
Ensures all feature requests are properly tracked and documented

## Implementation Details

### Design Decisions
_Document architectural and design choices here_

### Code Examples
```language
// Add implementation code examples here
```

### Technical Notes
_Add technical implementation notes, gotchas, dependencies_

### Progress Tracking
- [ ] Initial implementation
- [ ] Code review
- [ ] Testing complete
- [ ] Documentation updated

## Testing
- [ ] Unit tests added
- [ ] Integration tests passed
- [ ] Manual testing completed

---
Requirement defined in: REQUIREMENTS.md#REQ-0001
```

The requirement to process is: REQ-