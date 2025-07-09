# Claude Commands Analysis Report
Generated: 2025-01-09 16:18:00

## Executive Summary

Analyzed 13 command files totaling ~1,400 lines. Found significant opportunities for improvement in consistency, clarity, and structure. Key issues include:
- Inconsistent formatting and instruction styles
- Verbose commands with unclear priorities
- Missing critical error handling steps
- Duplicated patterns across multiple commands
- Poor separation of concerns

## Detailed Analysis by Command

### 1. /checkpoint (29 lines)
**Quality**: Good - Clear, concise, single-purpose
**Issues Found**:
- None significant
**Improvements Needed**:
- Could use more explicit error handling for TodoRead failure
**Shared Patterns**: Timestamp generation, file writing

### 2. /clean-wisdom (148 lines) ⚠️
**Quality**: Poor - Extremely verbose and complex
**Issues Found**:
- Too many responsibilities mixed together
- Unclear prioritization of steps
- Cross-project analysis feels tacked on (lines 113-122)
- Overly detailed formatting instructions
**Improvements Needed**:
- Break into smaller, focused sections
- Extract pattern analysis logic
- Move cross-project prompt to separate command
**Shared Patterns**: File reading/writing, timestamp usage, directory operations

### 3. /find-missing-tests (4 lines) ❌
**Quality**: Very Poor - Critically incomplete
**Issues Found**:
- No actual implementation details
- Missing file/directory scanning logic
- No guidance on test identification
- Vague instruction to "be very good"
**Improvements Needed**:
- Complete rewrite with specific steps
- Add language-specific test detection
- Include output format specification
**Shared Patterns**: GitHub issue creation

### 4. /make-github-issues (8 lines) ❌
**Quality**: Very Poor - Critically incomplete
**Issues Found**:
- Nearly identical to find-missing-tests
- No implementation guidance
- Missing duplicate detection logic despite mentioning it
- Vague quality instructions
**Improvements Needed**:
- Merge with find-missing-tests or differentiate clearly
- Add specific review criteria
- Implement duplicate checking
**Shared Patterns**: GitHub issue creation

### 5. /req-to-issue (147 lines)
**Quality**: Good - Well-structured with clear error handling
**Issues Found**:
- Some redundancy with /req command's issue creation
- Very detailed GitHub issue template could be extracted
**Improvements Needed**:
- Consider merging into /req as a subcommand
- Extract issue template to shared location
**Shared Patterns**: GitHub CLI usage, error handling, file updates

### 6. /req (263 lines) ⚠️
**Quality**: Fair - Comprehensive but overly complex
**Issues Found**:
- Longest command file with multiple responsibilities
- Complex duplicate detection logic
- Inline GitHub issue creation duplicates req-to-issue
- Mixed concerns (CRUD operations + GitHub integration)
**Improvements Needed**:
- Split into focused subcommands
- Extract shared GitHub issue logic
- Simplify duplicate detection algorithm
**Shared Patterns**: File I/O, GitHub CLI, requirement management

### 7. /security-review (71 lines)
**Quality**: Good - Clear structure and actionable steps
**Issues Found**:
- Could benefit from more specific grep patterns
- Missing some modern security concerns (CORS, CSP)
**Improvements Needed**:
- Add more comprehensive pattern library
- Include framework-specific checks
**Shared Patterns**: Grep usage, report generation

### 8. /standards (30 lines)
**Quality**: Good - Concise and clear
**Issues Found**:
- Relies on external CLAUDE.md files without validation
- No specific compliance checks defined
**Improvements Needed**:
- Add validation for CLAUDE.md existence
- Define specific compliance checks
**Shared Patterns**: File reading, planning mode usage

### 9. /start (107 lines)
**Quality**: Good - Well-structured session initialization
**Issues Found**:
- Complex merge logic could be clearer
- Some redundancy with checkpoint handling
**Improvements Needed**:
- Simplify todo merge algorithm description
- Extract git status logic to shared pattern
**Shared Patterns**: Git operations, todo management, file checks

### 10. /tool (11 lines)
**Quality**: Fair - Too minimal
**Issues Found**:
- Just a checklist without actionable steps
- No actual tool loading logic
**Improvements Needed**:
- Add actual implementation steps
- Integrate with standards checking
**Shared Patterns**: File reading

### 11. /wisdom-triggers (52 lines)
**Quality**: Excellent - Clear patterns and examples
**Issues Found**:
- None - this is more of a reference than a command
**Improvements Needed**:
- Consider moving to documentation rather than commands
**Shared Patterns**: Pattern matching, wisdom capture

### 12. /wisdom (72 lines)
**Quality**: Good - Clear purpose and behavior
**Issues Found**:
- Some overlap with clean-wisdom functionality
- Could be more explicit about pattern application
**Improvements Needed**:
- Add examples of pattern application
- Clarify relationship with clean-wisdom
**Shared Patterns**: File reading, pattern application

### 13. /wrap-session (188 lines) ⚠️
**Quality**: Fair - Comprehensive but overly complex
**Issues Found**:
- Second longest file with 11 sequential steps
- Mixed concerns (git, todos, wisdom, permissions)
- Tool permission management feels out of place
- Complex conditionals throughout
**Improvements Needed**:
- Break into smaller, focused functions
- Extract permission management to separate command
- Simplify step dependencies
**Shared Patterns**: Todo management, git operations, file creation

## Shared Patterns to Extract

### 1. **Timestamp Generation**
Used in: checkpoint, clean-wisdom, wrap-session
```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M")
```

### 2. **Git Status Checking**
Used in: start, wrap-session
- Branch detection
- Uncommitted changes check
- Recent commits listing

### 3. **Todo Management**
Used in: checkpoint, start, wrap-session
- TodoRead usage
- Status mapping (pending/in_progress/completed)
- Merge logic

### 4. **GitHub Issue Creation**
Used in: req, req-to-issue, find-missing-tests, make-github-issues
- Issue template formatting
- Label assignment
- gh CLI usage

### 5. **File Existence Validation**
Used in: Most commands
- Check before read/write
- Create directories as needed
- Handle missing files gracefully

### 6. **Directory Navigation**
Used in: Most commands
```
cd <working directory from environment info>
```

## Prioritized Recommendations

### Critical (Fix Immediately)
1. **Complete find-missing-tests and make-github-issues** - Currently unusable
2. **Consolidate GitHub issue creation** - Extract shared logic from req/req-to-issue
3. **Add error handling** - Many commands assume success without validation

### High Priority
1. **Refactor clean-wisdom** - Break into focused steps, remove cross-project prompt
2. **Simplify wrap-session** - Extract permission management, reduce complexity
3. **Merge related commands** - Combine req/req-to-issue, find-missing-tests/make-github-issues

### Medium Priority
1. **Extract shared patterns** - Create common includes for timestamps, git ops, etc.
2. **Standardize formatting** - Consistent structure across all commands
3. **Improve tool command** - Add actual implementation beyond checklist

### Low Priority
1. **Move wisdom-triggers** - Convert to documentation rather than command
2. **Add validation** - Ensure required files exist before operations
3. **Enhance security-review** - Add modern security patterns

## Recommended Command Structure Template

```markdown
# /command-name

Brief one-line description of what this command does.

## Prerequisites
- Required files/state
- Required tools

## Arguments
- $ARGUMENTS parsing if applicable

## Process

### Step 1: Validate Environment
- Check prerequisites
- Validate arguments
- Set up working directory

### Step 2: Core Operations
- Main logic here
- Clear, numbered steps
- Error handling inline

### Step 3: Output
- Standardized output format
- Success/failure indicators

## Error Handling
- Specific error cases
- User-friendly messages
- Recovery suggestions

## Example Usage
/command-name [arguments]
Expected output: ...
```

## Consistency Improvements

1. **Standardize output indicators**:
   - ✅ Success
   - ❌ Error
   - ⚠️ Warning
   - 💡 Suggestion
   - 📚 Information

2. **Consistent error handling**:
   - Always validate before operations
   - Provide clear error messages
   - Suggest recovery actions

3. **Unified git operations**:
   - Always check authentication first
   - Handle both GitHub and non-GitHub repos
   - Consistent status checking

This analysis reveals significant opportunities to improve command quality through consolidation, standardization, and extraction of shared patterns. The most critical issues are the incomplete commands that provide no value in their current state.