Parse the arguments provided: $ARGUMENTS

IMPORTANT: Change to project root directory before file operations.
Use the working directory from the environment info as the project root.

## Primary Usage: Add New Requirement
If arguments don't start with "list" or "status", treat as new requirement description:

1. Check if REQUIREMENTS.md exists in project root
   - If not, create it from template:
     ```bash
     cp ~/.local/share/chezmoi/dot_claude/templates/REQUIREMENTS.md ./REQUIREMENTS.md
     ```
   - Replace template placeholders:
     - "[Provide context...]" → "Tracks requirements for this project"
     - "[Describe the high-level...]" → "Requirements-driven development approach"

2. Check for related existing requirements:
   - Read REQUIREMENTS.md and extract all requirements with ID, name, description, status
   - Skip requirements with status "Completed" or "Deprecated"
   
   Check for relationships in this order:
   a. Direct REQ-ID reference: If description contains "REQ-XXXX"
   b. Strong keyword match: >70% of significant words match
   c. Semantic similarity: Description appears to extend/clarify existing requirement
   d. Domain overlap: Mentions same components, features, or areas
   
   If related requirement found:
   ```
   📎 This appears related to existing requirement:
   REQ-XXXX: [existing requirement name]
   Description: [existing description]
   GitHub Issue: [#XX or "Not created"]
   
   Would you like to:
   1. Add this as detail to the existing requirement (recommended)
   2. Create a new separate requirement
   
   Reply with 1 or 2:
   ```
   
   - Wait for user response
   - If "1" or no clear response, proceed to step 2a (add detail)
   - If "2", continue to step 3 (create new requirement)
   
   2a. Add detail to existing requirement:
   - Extract the REQ-ID and GitHub issue number (if exists)
   - If GitHub issue exists and we're in a GitHub repo:
     ```bash
     gh issue comment [issue-number] --body "[New description provided by user]
     
     ---
     *Added via `/req` command*"
     ```
     Output: "✅ Added detail to REQ-XXXX via GitHub issue comment #[number]"
   
   - If no GitHub issue or not in GitHub repo:
     - Find the requirement in REQUIREMENTS.md
     - After the existing description, add:
       ```
       - **Additional Details**: [timestamp] - [New description]
       ```
     - If "Additional Details" section already exists, append to it
     Output: "✅ Added detail to REQ-XXXX in REQUIREMENTS.md"
   
   - Exit after adding detail (don't create new requirement)

3. Find highest existing REQ number:
   - Search for pattern: `REQ-(\d{4}):`
   - If no requirements exist, start at REQ-0001
   - Otherwise, increment highest by 1
   - Format with leading zeros (e.g., REQ-0001, REQ-0029)

4. Extract requirement name from description:
   - Take first 5-8 words or up to 50 characters
   - Remove articles (a, an, the)
   - Capitalize appropriately

5. Generate rationale:
   - Analyze the description to understand the value proposition
   - Create 1-2 sentences explaining why this requirement matters
   - Focus on business value or technical necessity

6. Determine appropriate section:
   - If REQ <= 0009: Version 1.0 - Foundation
   - If REQ <= 0019: Version 1.1 - Enhancements  
   - If REQ >= 0020: Version 2.0 - Major Features

7. Add requirement at end of appropriate section:
   ```markdown
   #### REQ-XXXX: [Requirement name]
   - **Priority**: Medium
   - **Status**: Pending
   - **GitHub Issue**: Not created
   - **Description**: [Full description provided by user]
   - **Rationale**: [Generated rationale]
   - **Implementation**: See GitHub issue for details
   ```

8. Check if in a Git repository with GitHub remote:
   ```bash
   git rev-parse --git-dir 2>/dev/null && git remote get-url origin 2>/dev/null | grep -q github.com
   ```
   
   If in GitHub repository:
   a. Check GitHub CLI authentication:
      ```bash
      gh auth status
      ```
      - If not authenticated, note in output but continue
   
   b. If authenticated, create GitHub issue:
      - Prepare issue body:
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
      
      - Create issue:
        ```bash
        gh issue create \
          --title "REQ-XXXX: [requirement name]" \
          --label "requirement" \
          --label "priority:medium" \
          --body "[prepared body]"
        ```
      
      - Capture issue number and update REQUIREMENTS.md
      - Replace "GitHub Issue: Not created" with "GitHub Issue: #[number]"

9. Output based on what happened:
   
   If GitHub issue created:
   ```
   ✅ Added REQ-XXXX: [Requirement name]
   
   Priority: Medium | Status: Pending
   Section: [Version X.X - Section Name]
   GitHub Issue: #[number] (created)
   
   View issue: gh issue view [number]
   ```
   
   If no GitHub repo or not authenticated:
   ```
   ✅ Added REQ-XXXX: [Requirement name]
   
   Priority: Medium | Status: Pending
   Section: [Version X.X - Section Name]
   
   Note: GitHub issue not created (not in GitHub repo or not authenticated)
   To create issue later: /req-to-issue REQ-XXXX
   ```

## Subcommand: list
If arguments is exactly "list":

1. Check if REQUIREMENTS.md exists
   - If not: "No REQUIREMENTS.md found. Use `/req add <description>` to create your first requirement."

2. Read REQUIREMENTS.md and extract all requirements matching pattern: `#### REQ-\d{4}: (.+)`

3. For each requirement, extract:
   - REQ ID
   - Name (from heading)
   - Priority (from **Priority**: line)
   - Status (from **Status**: line)
   - GitHub Issue (from **GitHub Issue**: line)

4. Format output as:
   ```
   ## Project Requirements
   
   ### Version 1.0 - Foundation
   REQ-0001: [Name] - High priority - Implemented (#23)
   REQ-0002: [Name] - Medium priority - Pending
   
   ### Version 1.1 - Enhancements
   REQ-0010: [Name] - Low priority - In Progress (#45)
   
   ### Summary
   Total: 3 requirements
   By Status: Implemented (1), In Progress (1), Pending (1)
   By Priority: High (1), Medium (1), Low (1)
   ```

## Subcommand: status
If arguments starts with "status REQ-":

1. Extract REQ-ID from arguments (e.g., "status REQ-0001" → "REQ-0001")
   - Validate REQ-ID format (REQ-XXXX where X is digit)
   - If invalid: "Invalid requirement ID format. Use REQ-XXXX (e.g., REQ-0001)"

2. Check if REQUIREMENTS.md exists
   - If not: "No REQUIREMENTS.md found. No requirements tracked yet."

3. Search for requirement by ID

4. If found, display:
   ```
   ## REQ-XXXX: [Requirement name]
   
   Priority: [High/Medium/Low]
   Status: [Status]
   GitHub Issue: [#XX or "Not created"]
   
   Description:
   [Full description]
   
   Rationale:
   [Rationale text]
   
   [If GitHub issue exists:]
   → View implementation details: gh issue view XX
   ```

5. If not found:
   "Requirement REQ-XXXX not found. Use `/req list` to see all requirements."

## Error Handling
- If no arguments provided ($ARGUMENTS is empty): "Usage: /req <description> | /req list | /req status REQ-XXXX"
- If invalid status command: "Usage: /req status REQ-XXXX (e.g., /req status REQ-0001)"