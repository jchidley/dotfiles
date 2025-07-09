# Command Quality Audit
Created: 2025-01-09 16:18

## Executive Summary

Audited 13 commands in dot_claude/commands/ for quality, consistency, and improvement opportunities.

### Key Findings
- 2 commands are non-functional (find-missing-tests, make-github-issues)
- 3 commands exceed 150 lines (req: 263, wrap-session: 188, clean-wisdom: 148)
- Significant duplication in GitHub operations, timestamps, and git status checks
- Inconsistent formatting and output styles across commands

## Command-by-Command Analysis

### 🔴 Critical Issues (Fix Immediately)

#### 1. `/find-missing-tests` (4 lines)
**Issues**: No implementation, just a vague TODO
**Action**: Either implement or remove from active commands

#### 2. `/make-github-issues` (8 lines)  
**Issues**: Nearly identical to find-missing-tests, no real logic
**Action**: Merge with req-to-issue or remove

### 🟡 High Complexity (Refactor Needed)

#### 3. `/req` (263 lines)
**Issues**: 
- Longest command file
- Mixes requirement parsing, formatting, duplicate checking
- Complex conditionals throughout
**Action**: Split into sub-commands or extract shared logic

#### 4. `/wrap-session` (188 lines)
**Issues**:
- 11 sequential steps with deep nesting
- Permission management mixed with core logic
- Complex todo merging logic duplicated from /start
**Action**: Extract permission handling and todo management

#### 5. `/clean-wisdom` (148 lines)
**Issues**:
- Mixes pattern analysis, GitHub searching, cross-repo logic
- Complex Python script embedded
**Action**: Extract Python analysis to separate tool

### 🟢 Good Examples (Minor Improvements)

#### 6. `/checkpoint` (39 lines)
**Good**: Clear, focused, single responsibility
**Improve**: Add example output format

#### 7. `/security-review` (61 lines)
**Good**: Well-structured, clear sections
**Improve**: Standardize output indicators

#### 8. `/standards` (48 lines)
**Good**: Simple, effective validation
**Improve**: Add summary at end

### Shared Patterns to Extract

1. **GitHub Operations** (used in 4 commands)
```markdown
- Check if in git repo
- Get current branch  
- Create GitHub issue with labels
- Handle auth errors
```

2. **Timestamp Generation** (used in 5 commands)
```markdown
- Get current date/time
- Format as YYYY-MM-DD HH:MM
- Use for file naming
```

3. **Todo List Management** (used in 3 commands)
```markdown
- Parse markdown checkboxes to todo format
- Merge with existing todos
- Handle status mapping
```

4. **Git Status Checks** (used in 4 commands)
```markdown
- Check if directory is git repo
- Get current branch
- Check for uncommitted changes
```

## Proposed Improvements

### 1. Create Reference Files
- `references/github-operations.md` - Shared GitHub CLI patterns
- `references/todo-management.md` - Todo parsing/merging logic
- `references/output-formatting.md` - Consistent indicators and styles

### 2. Command Template
```markdown
# /command-name

## Purpose
One-line description

## Prerequisites
- Required tools/state

## Process
1. Step one
2. Step two
   - Sub-step if needed

## Output Format
```
Example output here
```

## Error Handling
- Condition: Action
```

### 3. Complexity Limits
- Maximum 100 lines per command
- Extract complex logic to tools or sub-commands
- Use references for shared patterns

### 4. Consistent Indicators
- ✅ Success/Completed
- ❌ Error/Failed  
- ⚠️ Warning/Attention
- 💡 Tip/Suggestion
- 📚 Information/Reference
- 🔍 Searching/Analyzing
- 📝 Creating/Writing

## Implementation Priority

1. **Immediate** (This session):
   - Remove/fix non-functional commands
   - Create references/ directory structure
   - Extract GitHub operations pattern

2. **Next Session**:
   - Refactor wrap-session command
   - Simplify req command
   - Standardize all output formats

3. **Future**:
   - Add examples to all commands
   - Create command testing framework
   - Build command documentation generator