Execute the requested /req subcommand:

For /req check <description>:
1. Analyze if the description represents a project requirement (new capability/constraint) vs regular task
2. Output: "This IS/IS NOT a project requirement. [Brief reason]"
3. If requirement, suggest: "Use /req add to track this requirement"

For /req add <description>:
1. Check if REQUIREMENTS.md exists, create from template if not
2. Find highest REQ number, increment for new requirement
3. Add new requirement with format:
   #### REQ-XXXX: [Brief name from description]
   - **Priority**: Medium
   - **Status**: Pending
   - **GitHub Issue**: Not created
   - **Description**: [Full description provided]
   - **Rationale**: [Why this is needed]
   - **Implementation**: See GitHub issue for details
4. Output: "Added REQ-XXXX: [name]"

For /req list:
1. Read REQUIREMENTS.md
2. Extract all requirements with ID, name, status, priority
3. Format as table or list
4. Show summary counts by status

For /req status <REQ-XXXX>:
1. Read REQUIREMENTS.md
2. Find specified requirement
3. Display all fields for that requirement
4. If GitHub issue exists, note: "See issue #X for implementation details"