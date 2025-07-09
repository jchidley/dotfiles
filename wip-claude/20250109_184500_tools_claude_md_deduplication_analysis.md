# Tools/CLAUDE.md Deduplication Analysis
Created: 2025-01-09 18:45

## Purpose
Analyze what should be removed from tools/CLAUDE.md to avoid duplication with:
- dot_claude/CLAUDE.md (global config - ALWAYS active)
- claude-hooks (automatic enforcement - ALWAYS active)

## Items to REMOVE from tools/CLAUDE.md

### 1. Python Version Requirements (Lines 86-143)
**Why remove**: Entirely duplicated in dot_claude/CLAUDE.md
- Python 3.12 enforcement
- uv/uvx usage patterns  
- pip blocking
- All these patterns are global requirements

### 2. Basic Formatting Mentions (Lines 263, 270, 277)
**Why remove**: Hooks handle this automatically
- "Note: Formatting (black) and linting (ruff) are handled automatically by hooks"
- "Note: Formatting (cargo fmt) is handled automatically by hooks"
- "Note: Formatting (prettier) is handled automatically by hooks"
- These notes are redundant - hooks just do it

### 3. Bash Header Requirements (Lines 208-216)
**Why remove**: Hooks validate and enforce this
- The shebang, set -euo pipefail, die() function
- Already checked by validators.py
- Keep only the `set -e` gotchas (lines 218-225) as they're educational

### 4. File Validation Rules
**Why remove**: dot_claude/CLAUDE.md has "VALIDATE file existence before editing"
- This is a global requirement, not project-specific

### 5. Sudo Mentions
**Why remove**: dot_claude/CLAUDE.md has "NEVER run sudo directly"
- This is enforced globally

## Items to KEEP in tools/CLAUDE.md

### 1. Language Selection Philosophy (Lines 7-20)
**Why keep**: This is decision-making guidance, not enforceable by hooks
- "ALWAYS Start with Bash" principle
- Language escalation patterns
- This guides thinking, not just actions

### 2. Development Operational Modes (Lines 42-62)
**Why keep**: Complex behavioral patterns
- Implementation Mode
- Refactoring Mode  
- These guide entire workflows, not single actions

### 3. Testing Discipline - OCR 0% Lesson (Lines 98-129)
**Why keep**: Philosophy and complex patterns
- Mutation testing requirements
- Test effectiveness principles
- Can't be mechanically enforced

### 4. Refactoring Discipline (Lines 130-158)
**Why keep**: Behavioral guidance for complex tasks
- Mechanical refactoring processes
- Anti-patterns to avoid
- Requires human judgment

### 5. Empirical Development Principle (Lines 73-97)
**Why keep**: Philosophy about data vs theory
- System invariants pattern
- Regression evidence requirements
- Guides decision-making

### 6. LLM-Specific Anti-Patterns (Lines 172-186)
**Why keep**: Self-awareness patterns
- Tendencies to over-engineer
- Common Claude mistakes
- Can't be hook-enforced

### 7. Bash `set -e` Gotchas (Lines 218-225)
**Why keep**: Educational - explains WHY certain patterns fail
- The ((var++)) issue explanation
- Command substitution handling
- Helps understand hook warnings

### 8. Technical Debt Management (Lines 187-195)
**Why keep**: Periodic maintenance tasks
- Mutation testing schedules
- Coverage requirements
- Manual review processes

### 9. Repository Standards (Lines 239-244)
**Why keep**: Project conventions (some could become hooks later)
- Install paths
- Data storage patterns
- Commit message formats

## Recommended Structure for Cleaned tools/CLAUDE.md

1. **Development Philosophy** (not enforceable)
   - Language selection principles
   - Empirical development
   - Code quality principles

2. **Operational Modes** (complex behaviors)
   - Implementation Mode
   - Refactoring Mode
   - Mode triggers and exits

3. **Testing Philosophy** (beyond mechanical checks)
   - OCR 0% lesson
   - Mutation testing discipline
   - Test quality principles

4. **Complex Disciplines** (require judgment)
   - Refactoring processes
   - Plan execution discipline
   - When tests feel contrived

5. **Educational Content** (the "why")
   - Bash set -e gotchas
   - LLM-specific anti-patterns
   - Pedantic languages as force multipliers

6. **Project Standards** (build on global)
   - Repository structure
   - Technical debt schedules
   - Tool-specific disciplines (beyond formatting)

## Summary

Remove ~100 lines of duplication, focusing tools/CLAUDE.md on:
1. **Philosophy and principles** that guide decisions
2. **Complex patterns** that require human judgment  
3. **Educational content** that explains the "why"
4. **Project-specific standards** that extend global rules

This creates a clear hierarchy:
- **dot_claude/CLAUDE.md**: Universal rules (always active)
- **claude-hooks**: Mechanical enforcement (automatic)
- **tools/CLAUDE.md**: Philosophy, complex patterns, project-specific guidance