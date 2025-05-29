# /req-to-issue - Create GitHub Issue from Requirement

**CLAUDE INSTRUCTION**: When the user invokes this command with a REQ number, YOU MUST execute the following actions to create a GitHub issue.

## Command Action

When user types `/req-to-issue REQ-XXXX`, execute these steps:

1. **Locate REQUIREMENTS.md** in current directory
   - If not found: "Error: No REQUIREMENTS.md found in current directory"
2. **Read and parse** the specified requirement (REQ-XXXX)
   - Extract: name, description, rationale, priority, status, dependencies
3. **Create GitHub issue** using gh command:
   - Title: `[REQ-XXXX] Requirement Name`
   - Labels: `requirement`, priority level (`high-priority`, `medium-priority`, `low-priority`)
   - Body: Detailed template with all implementation sections
4. **Update REQUIREMENTS.md**:
   - Replace `GitHub Issue: Not created` with `GitHub Issue: #[issue-number]`
   - Save the updated file
5. **Commit the change**:
   - Message: `docs: link REQ-XXXX to GitHub issue #[number]`
6. **Display result**:
   - "✅ Created issue #[number] for REQ-XXXX"
   - "📋 REQUIREMENTS.md updated with issue link"
   - Show the issue URL

## Execution Steps

1. Check for REQUIREMENTS.md in current directory
2. Parse requirement details from the file
3. Build comprehensive issue body from template
4. Create issue with gh command and capture issue number
5. Update REQUIREMENTS.md with issue number
6. Commit the update
7. Display success message with issue URL

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