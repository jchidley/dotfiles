# /req-to-issue - Create GitHub Issue from Requirement

**CLAUDE INSTRUCTION**: When the user invokes this command with a REQ number, YOU MUST execute the following actions to create a GitHub issue.

## Command Action

When user types `/req-to-issue REQ-XXXX`, execute these steps:

1. **Read the requirement** from REQUIREMENTS.md for the specified REQ number
2. **Extract details**: name, description, rationale, priority, dependencies
3. **Create GitHub issue** using gh command with:
   - Title: `[REQ-XXXX] Requirement Name`
   - Labels: `requirement`, priority level (high/medium/low)
   - Detailed body with implementation sections
4. **Update REQUIREMENTS.md** to include the created issue number
5. **Return the issue URL** to the user

## Execution Steps

1. First, read REQUIREMENTS.md and find the requirement
2. Create the issue body with all sections for detailed notes
3. Use gh issue create command
4. Update REQUIREMENTS.md with the issue number
5. Commit the REQUIREMENTS.md update

## Implementation Template

When creating the GitHub issue, use this body template:

```markdown
## Description
[Insert requirement description from REQUIREMENTS.md]

## Rationale
[Insert rationale from REQUIREMENTS.md]

## Dependencies
[List any dependencies from REQUIREMENTS.md or "None"]

## Implementation Details

### Design Decisions
- [ ] Define overall architecture approach
- [ ] Identify key components/modules
- [ ] Document API contracts/interfaces
- [ ] Consider error handling strategy

### Technical Approach
```
// Document implementation approach here
// Include pseudo-code or architecture diagrams
```

### Code Examples
```[language]
// Add implementation code examples as work progresses
// Include both successful and edge cases
```

### Technical Notes
- Configuration requirements:
- Performance considerations:
- Security implications:
- Integration points:
- Known limitations:

### Progress Tracking
- [ ] Design review completed
- [ ] Initial implementation
- [ ] Code review feedback addressed
- [ ] Edge cases handled
- [ ] Error handling implemented
- [ ] Performance optimized
- [ ] Documentation updated

## Testing Strategy

### Unit Tests
- [ ] Core functionality tests
- [ ] Edge case tests
- [ ] Error condition tests
- [ ] Mock/stub dependencies

### Integration Tests
- [ ] API endpoint tests
- [ ] Database integration tests
- [ ] External service integration tests

### Manual Testing
- [ ] Developer testing checklist
- [ ] User acceptance criteria
- [ ] Performance benchmarks

## Documentation
- [ ] API documentation
- [ ] User guide updates
- [ ] Developer documentation
- [ ] Release notes

---
📋 Requirement defined in: [REQUIREMENTS.md#REQ-XXXX](../REQUIREMENTS.md#REQ-XXXX)
```

## Example gh Command

```bash
gh issue create \
  --title "[REQ-0001] Requirement Name" \
  --label "requirement,high-priority" \
  --body "$(cat <<'EOF'
[Issue body content from template above]
EOF
)"
```