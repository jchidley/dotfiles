# GitHub Issue Template for Requirements

Standard template for creating requirement issues.

## Issue Body Template
```markdown
## Requirement: REQ-XXXX

**Description**: [description from requirement]

**Rationale**: [rationale from requirement]

## Implementation Plan
<!-- TODO: Add design decisions and technical approach -->

### Technical Approach
- [ ] Define interfaces/contracts
- [ ] Implementation strategy
- [ ] Integration points
- [ ] Error handling approach

### Code Structure
```
// TODO: Add key interfaces or usage examples
```

## Testing Strategy
- [ ] Unit tests for core functionality
- [ ] Integration tests for system interactions
- [ ] Edge cases and error scenarios
- [ ] Performance considerations

## Progress Tracking
- [ ] Design review complete
- [ ] Implementation started
- [ ] Tests written (coverage target: 80%+)
- [ ] Documentation updated
- [ ] Code review complete
- [ ] Merged to main branch

## Acceptance Criteria
<!-- TODO: Define specific criteria for completion -->

## Notes
<!-- Implementation discoveries, decisions, blockers -->

---
*This issue tracks implementation of REQ-XXXX from REQUIREMENTS.md*
*Priority: Medium | Created from requirement definition*
```

## Issue Creation Command
```bash
gh issue create \
  --title "REQ-XXXX: [requirement name]" \
  --label "requirement" \
  --label "priority:medium" \
  --body "[prepared body]"
```