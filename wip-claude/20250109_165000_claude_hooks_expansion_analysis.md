# Claude Code Hooks Expansion Analysis
Created: 2025-01-09 16:50
Updated: 2025-01-09 18:55

## Overview

After implementing basic formatting/linting hooks and updating tools/CLAUDE.md, this document analyzes what additional mechanical patterns could be moved from CLAUDE.md to hooks. Now updated with clear separation: dot_claude/CLAUDE.md (global rules), hooks (mechanical enforcement), tools/CLAUDE.md (philosophy).

## Current State

### Already in Hooks
- **Python**: black formatting, ruff linting
- **Rust**: cargo fmt
- **TypeScript/JS**: prettier formatting
- **Bash**: shellcheck validation, header requirements, dangerous pattern detection
- **Pre-commit**: integration with existing frameworks

### Remains in CLAUDE.md
- Language selection philosophy
- Development modes and approaches
- Testing philosophy and empirical validation
- Behavioral guidelines and anti-patterns

## Additional Patterns That Could Be Automated

### 1. ABOUTME Comment Enforcement

**Current Rule**: "Start files with 2-line ABOUTME: comment"

**Hook Implementation**:
```bash
# Check files > 10 lines for ABOUTME comment
if [[ $(wc -l < "$file") -gt 10 ]] && ! head -n 5 "$file" | grep -q "ABOUTME:"; then
    echo "WARNING: Missing ABOUTME comment in $file"
fi
```

**Benefit**: Ensures documentation consistency without manual reminders

### 2. Test File Creation Reminders

**Current Practice**: Implicit expectation to create tests

**Hook Implementation**:
```bash
# For implementation files, check for corresponding test
if [[ "$file" =~ \.(py|rs|ts|js)$ ]] && [[ ! "$file" =~ (test|spec) ]]; then
    test_patterns=("test_${base}.${ext}" "${base}_test.${ext}" "${base}.test.${ext}" "${base}.spec.${ext}")
    for pattern in "${test_patterns[@]}"; do
        if [[ -f "$pattern" ]]; then
            found_test=true
            break
        fi
    done
    if [[ -z "$found_test" ]]; then
        echo "REMINDER: Consider creating test file for $file"
    fi
fi
```

### 3. Test Pattern Validation

**Current Rule**: "Tests MUST verify actual values, not just structure" (OCR 0% Lesson)

**Hook Implementation**:
```bash
# Detect ineffective test patterns
if [[ "$file" =~ test.*\.(py|js|ts)$ ]]; then
    # Check for structure-only assertions
    if grep -E 'assert.*is not None|assert.*!= null|expect.*toBeDefined' "$file" | grep -v "# .*effective"; then
        echo "WARNING: Test may have ineffective assertions (structure-only checks)"
    fi
    # Check for missing concrete assertions
    if ! grep -E 'assert.*==|expect.*toBe[^D]|expect.*toEqual' "$file"; then
        echo "WARNING: Test lacks concrete value assertions"
    fi
fi
```

### 4. Console Output in Tests

**Current Rule**: "Test output MUST be pristine"

**Hook Implementation**:
```bash
# Detect console output in test files
if [[ "$file" =~ test.*\.(py|js|ts|rs)$ ]]; then
    if grep -E 'print\(|console\.|println!|dbg!' "$file" | grep -v "^[[:space:]]*//\|^[[:space:]]*#"; then
        echo "WARNING: Test file contains console output - tests should have pristine output"
    fi
fi
```

### 5. Dangerous Code Patterns

**Beyond bash arithmetic, detect common anti-patterns**:

```bash
# Magic numbers without context
if grep -E '(return|=)[[:space:]]*[0-9]{3,}[[:space:]]*[;$]' "$file" | grep -v "//\|#.*why"; then
    echo "WARNING: Magic number detected without explanation"
fi

# Missing error handling
if [[ "$file" =~ \.py$ ]] && grep -E '\.read\(|\.write\(|open\(' "$file" | grep -v "try:\|with "; then
    echo "WARNING: File operations without error handling"
fi
```

### 6. Import/Dependency Validation

**Detect potentially missing dependencies**:

```bash
# Check Python imports against requirements
if [[ "$file" =~ \.py$ ]]; then
    imports=$(grep -E '^(import|from) ' "$file" | awk '{print $2}' | cut -d. -f1 | sort -u)
    # Check against pyproject.toml or requirements.txt
fi

# Check JS/TS imports against package.json
if [[ "$file" =~ \.(js|ts)x?$ ]]; then
    # Extract and validate imports
fi
```

### 7. File Location Standards

**Current Rule**: "Install executables to ~/.local/bin/"

**Hook Implementation**:
```bash
# When creating executable scripts
if [[ "$file" =~ ^executable_ ]] || grep -q "^#!/" "$file"; then
    if [[ ! "$file" =~ \.local/bin/ ]] && [[ ! "$file" =~ /tests?/ ]]; then
        echo "REMINDER: Executable scripts should be installed to ~/.local/bin/"
    fi
fi
```

### 8. README Structure Validation

**Current Rule**: "Always put commands/usage at the top"

**Hook Implementation**:
```bash
if [[ "$file" == "README.md" ]]; then
    # Check for usage section near the top
    if ! head -n 30 "$file" | grep -E '^##.*(Usage|Quick Start|Commands|Getting Started)'; then
        echo "WARNING: README.md should have usage/commands section near the top"
    fi
fi
```

### 9. Commit Message Format Validation

**While not a file hook, could validate staged commit messages**:

```bash
# Validate commit message format
if [[ "$event" == "pre-commit" ]]; then
    msg=$(git log -1 --pretty=%B)
    if ! echo "$msg" | grep -E '^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+'; then
        echo "ERROR: Commit message must follow conventional format"
        exit 1
    fi
fi
```

### 10. Documentation Freshness

**Detect stale comments referencing non-existent code**:

```bash
# Check if comments reference functions/variables that don't exist
# This is complex and might need a language-aware parser
```

## What Must Remain in CLAUDE.md

### Philosophical Guidelines
- **Language Selection Logic**: "Can it be done with bash?" requires judgment
- **Development Modes**: Planning vs Implementation vs Refactoring
- **Empirical Development**: "Test actual behavior, don't trust documentation"
- **Thinking Triggers**: When to think/ultrathink

### Complex Decision Making
- When to refactor vs rewrite
- Architecture and design decisions
- Performance vs readability tradeoffs
- "Smallest reasonable change" judgment

### Behavioral Anti-Patterns
- "While I'm here..." tendency
- Over-engineering simple solutions
- Adding features not requested
- These require self-awareness, not mechanical checks

### Context-Dependent Rules
- "Never make unrelated changes" - requires understanding of "related"
- "Ask permission before reimplementing" - requires judgment
- "Check conversation history" - requires memory and context

## Implementation Recommendations

### Phase 1: High-Value, Low-Complexity Hooks
1. **ABOUTME comment checker** - Simple pattern match, high documentation value
2. **Test file reminder** - Encourages TDD without being intrusive
3. **Console output in tests** - Maintains test quality standards
4. **README structure validator** - Ensures consistent documentation

### Phase 2: Medium-Complexity Hooks
1. **Test effectiveness validator** - Detect structure-only assertions
2. **Magic number detector** - Encourage self-documenting code
3. **File location validator** - Enforce project structure standards

### Phase 3: Advanced Hooks (Require More Sophistication)
1. **Import/dependency validator** - Needs project context
2. **Documentation freshness checker** - Needs code parsing
3. **Refactoring safety analyzer** - Needs to understand intent

## Benefits of This Approach

1. **Consistency**: Mechanical rules are always enforced
2. **Learning**: Codebase becomes the teacher through consistency
3. **Focus**: Claude can focus on logic and design rather than mechanics
4. **Clarity**: Clear separation between "what" (hooks) and "why" (CLAUDE.md)

## Potential Drawbacks

1. **Over-automation**: Too many warnings could be noisy
2. **False Positives**: Pattern matching has limitations
3. **Context Loss**: Some rules need context that hooks can't provide
4. **Maintenance**: More hooks mean more maintenance

## Conclusion

The expansion of hooks should focus on patterns that are:
- **Mechanical**: Can be detected with simple patterns
- **Valuable**: Prevent real issues or improve quality
- **Non-intrusive**: Warn rather than block (except for critical issues)
- **Clear**: Obvious what needs to be fixed

This maintains CLAUDE.md as the source of wisdom and judgment while hooks handle the mechanical enforcement, creating a powerful combination of philosophical guidance and practical automation.