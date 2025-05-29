Parse requirement ID from command argument.

Read REQUIREMENTS.md and find specified requirement.
Extract: name, description, rationale, priority.

Create GitHub issue using gh CLI:
```bash
gh issue create \
  --title "REQ-XXXX: [requirement name]" \
  --label "requirement,priority:[priority]" \
  --body "[formatted body - see template below]"
```

Issue body template:
## Requirement: REQ-XXXX

**Description**: [from REQUIREMENTS.md]

**Rationale**: [from REQUIREMENTS.md]

## Implementation Plan
<!-- Design decisions and technical approach -->

### Technical Approach
- [ ] Define interfaces/contracts
- [ ] Implementation strategy
- [ ] Integration points

### Code Examples
```[language]
// Key interfaces or usage examples
```

## Testing Strategy
- [ ] Unit tests
- [ ] Integration tests
- [ ] Edge cases

## Progress Tracking
- [ ] Design complete
- [ ] Implementation started
- [ ] Tests written
- [ ] Documentation updated
- [ ] Code reviewed

## Notes
<!-- Implementation discoveries, decisions, blockers -->

---
*This issue tracks implementation of REQ-XXXX from REQUIREMENTS.md*

After creating issue:
1. Get issue number from gh output
2. Update REQUIREMENTS.md to change "GitHub Issue: Not created" to "GitHub Issue: #[number]"
3. Output: "Created GitHub issue #[number] for REQ-XXXX"

If gh auth required, output: "GitHub CLI authentication required. Run: gh auth login"