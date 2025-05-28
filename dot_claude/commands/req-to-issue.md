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
     - Implementation tracking section
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

## Implementation Tracking
- [ ] Update CLAUDE.md with requirement checking logic
- [ ] Create automated workflow for requirement capture
- [ ] Test with various request types

---
Requirement defined in: REQUIREMENTS.md#REQ-0001
```

The requirement to process is: REQ-