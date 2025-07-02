# /clean-wisdom

Distills patterns through repetition analysis to create refined PROJECT_WISDOM.md from raw discoveries.

When user runs `/clean-wisdom`, distill patterns from all wisdom files through repetition analysis and emphasis tracking.

## Pattern Distillery Process:

1. **Gather all wisdom sources**:
   - CURRENT_PROJECT_WISDOM.md (recent session discoveries)
   - ARCHIVE_PROJECT_WISDOM.md (historical patterns)
   - PROJECT_WISDOM.md (existing refined wisdom)
   - PROJECT_WISDOM_ARCHIVE_*.md files in subdirectories
   - sessions/SESSION_*.md files (historical session logs):
     - Extract from "Technical Insights" sections (if present)
     - Mine patterns from "Work Done" sections
     - Analyze "Failed Approaches" for anti-patterns

2. **Session Mining Process**:
   - For each session file, look for patterns using wisdom-triggers.md:
     - Technical discoveries in "Work Done" and "Technical Insights"
     - Failed approaches that inform anti-patterns
     - Evolution stories ("tried X, Y worked better")
   - Extract insights even if not explicitly marked as wisdom
   - Note session date and context for each discovered pattern

3. **Repetition Analysis**:
   - Count occurrences of each pattern across ALL sources (wisdom files + sessions)
   - Track which sessions/dates mentioned each pattern
   - Identify evolution of patterns (initial discovery → refinement → validation)
   - Note patterns that appear with different solutions (competing approaches)
   - Patterns found in multiple sessions get higher emphasis

4. **Pattern Emphasis Rules**:
   - **1-2 occurrences**: Standard entry
   - **3-5 occurrences**: Bold pattern name, expanded explanation
   - **6+ occurrences**: CORE PATTERN marker, top placement, detailed examples
   - **Conflicting patterns**: Document both approaches with context

5. **Output Structure** for PROJECT_WISDOM.md:
   ```markdown
   # PROJECT_WISDOM.md - [Project Name]
   
   Refined patterns distilled from [X] sessions through repetition analysis.
   
   ## CORE PATTERNS (6+ occurrences)
   
   ### 🔷 [Pattern Name] (used 12 times across 7 sessions)
   **When to use**: [Specific trigger condition from repeated context]
   **Pattern**:
   ```[language]
   [Copy-paste ready code - most refined version]
   ```
   **Why it works**: [Consolidated explanation from all occurrences]
   **Failed alternatives**: [All approaches that didn't work]
   **Evolution**: First seen [date], refined [date], validated [date]
   
   ## ESTABLISHED PATTERNS (3-5 occurrences)
   
   ### **[Pattern Name]** (used 4 times)
   [Similar structure but less emphasis]
   
   ## EMERGING PATTERNS (1-2 occurrences)
   
   ### [Pattern Name] (seen twice)
   [Standard format - may need more validation]
   ```

6. **Archive Management**:
   - Append CURRENT_PROJECT_WISDOM.md content to ARCHIVE_PROJECT_WISDOM.md
   - Clear CURRENT_PROJECT_WISDOM.md for next cycle
   - Add timestamp marker in ARCHIVE: `--- Archived from CURRENT on [date] ---`

7. **Safeguards**:
   - Never remove empirically validated constants
   - Preserve all "we tried X, Y worked better" evolution stories
   - Keep specific error messages and their solutions
   - Maintain version/tool-specific notes

## Analysis Output:

Report to user:
```
Wisdom Distillation Complete:

Sources Analyzed:
- [X] wisdom files (PROJECT, CURRENT, ARCHIVE)
- [Y] session files spanning [date range]
- [Z] total patterns extracted

Pattern Distribution:
- CORE patterns (6+ uses): [count]
- Established patterns (3-5 uses): [count]  
- Emerging patterns (1-2 uses): [count]
- Most repeated pattern: [name] (used [N] times across [M] sessions)

Session Mining Results:
- Found [A] patterns in sessions not yet in wisdom files
- Discovered [B] anti-patterns from failed approaches
- Identified [C] evolution sequences showing pattern refinement
- Example: "stderr for progress messages" found in 6 sessions but not in wisdom

Archive Management:
- Archive updated with [D] new entries
- CURRENT_PROJECT_WISDOM.md cleared for next cycle

Ready to apply refined patterns with /wisdom command.
```

## Special Cases:

**Competing Patterns**: When same problem has multiple solutions:
```markdown
### [Problem]: Multiple Approaches (seen 8 times total)

**Approach A** (used 5 times - preferred):
[Pattern A code]
**Context**: Works best when [conditions]

**Approach B** (used 3 times):
[Pattern B code]
**Context**: Consider when [different conditions]
```

**Evolution Tracking**: Show how patterns improved:
```markdown
### [Pattern Name] (evolved over 6 iterations)
**Current best practice**:
[Final refined pattern]

**Evolution notes**:
- v1 (2025-01-15): Basic approach, had [issue]
- v2 (2025-02-20): Added [improvement], fixed [issue]
- v3 (2025-03-10): Final refinement with [optimization]
```