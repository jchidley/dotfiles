Parse the requirement ID from the command argument.

NOTE: The `/req` command now automatically creates GitHub issues when in a GitHub repository.
This command is useful for:
- Creating issues for requirements that were added before automatic issue creation
- Recreating issues if they were deleted
- Creating issues after GitHub authentication is set up

IMPORTANT: Change to project root directory before file operations.
Use the working directory from the environment info as the project root.

## Step 1: Validate Input
1. Extract REQ-ID from command (expect format: `/req-to-issue REQ-XXXX`)
2. Validate format: must match pattern `REQ-\d{4}`
   - If invalid: "❌ Invalid requirement ID format. Expected: REQ-XXXX (e.g., REQ-0001)"
   - Exit if invalid

## Step 2: Check Prerequisites
1. Check if REQUIREMENTS.md exists in project root:
   ```bash
   test -f REQUIREMENTS.md
   ```
   - If not: "❌ No REQUIREMENTS.md found. Use `/req add <description>` to create requirements first."
   - Exit if missing

2. Check GitHub CLI authentication:
   ```bash
   gh auth status
   ```
   - If not authenticated: 
     ```
     ❌ GitHub CLI not authenticated. Please run:
     gh auth login
     
     Then retry this command.
     ```
   - Exit if not authenticated

## Step 3: Extract Requirement Details
1. Read REQUIREMENTS.md and search for the specific requirement ID
2. Extract the following fields using pattern matching:
   - **Requirement heading**: `#### REQ-XXXX: (.+)`
   - **Priority**: Line starting with `- **Priority**: (High|Medium|Low)`
   - **Status**: Line starting with `- **Status**: (.+)`
   - **GitHub Issue**: Line starting with `- **GitHub Issue**: (.+)`
   - **Description**: Line starting with `- **Description**: (.+)`
   - **Rationale**: Line starting with `- **Rationale**: (.+)`

3. If requirement not found:
   ```
   ❌ Requirement REQ-XXXX not found in REQUIREMENTS.md
   Use `/req list` to see available requirements.
   ```
   Exit if not found

4. If GitHub issue already exists (not "Not created"):
   ```
   ⚠️  Requirement REQ-XXXX already has GitHub issue: #XX
   View it with: gh issue view XX
   ```
   Exit if issue exists

## Step 4: Create GitHub Issue
1. Prepare issue body with proper formatting:
   ```markdown
   ## Requirement: REQ-XXXX
   
   **Description**: [extracted description]
   
   **Rationale**: [extracted rationale]
   
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
   *Priority: [priority] | Created from requirement definition*
   ```

2. Create the issue:
   ```bash
   gh issue create \
     --title "REQ-XXXX: [requirement name]" \
     --label "requirement" \
     --label "priority:[lowercase priority]" \
     --body "[prepared body]"
   ```

3. Capture the issue number from output (format: "https://github.com/owner/repo/issues/XX")

## Step 5: Update REQUIREMENTS.md
1. Read the entire REQUIREMENTS.md file
2. Find the line: `- **GitHub Issue**: Not created`
3. Replace with: `- **GitHub Issue**: #[issue-number]`
4. Write the updated content back to REQUIREMENTS.md

## Step 6: Provide Success Output
```
✅ Created GitHub issue #[number] for REQ-XXXX: [requirement name]

Priority: [priority]
Labels: requirement, priority:[priority]

View issue: gh issue view [number]
Edit issue: gh issue edit [number]

The REQUIREMENTS.md file has been updated with the issue number.
```

## Error Handling Summary
- Invalid REQ-ID format → Clear error with example
- Missing REQUIREMENTS.md → Suggest creating requirements first
- GitHub CLI not authenticated → Provide auth command
- Requirement not found → Suggest listing requirements
- Issue already exists → Show existing issue number
- Any gh command failure → Show exact error from GitHub CLI