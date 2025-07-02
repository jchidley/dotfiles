# /wisdom

Applies refined skeleton exemplars from PROJECT_WISDOM.md to current implementation tasks.

When user runs `/wisdom`, apply skeleton exemplars from accumulated project wisdom for current implementation needs.

## Pattern Discovery Process:

1. **Primary source: PROJECT_WISDOM.md** (refined patterns from /clean-wisdom)
   - Check for CORE PATTERNS (6+ uses) first
   - Then ESTABLISHED PATTERNS (3-5 uses)
   - Finally EMERGING PATTERNS (1-2 uses)

2. **Secondary source: CURRENT_PROJECT_WISDOM.md** (recent discoveries)
   - Check if no PROJECT_WISDOM.md exists
   - Or if working on cutting-edge features

3. **Extract actionable patterns**:
   - Copy-paste ready code blocks
   - Specific trigger conditions ("When to use")
   - Failed alternatives to avoid
   - Evolution notes for context

## Enhanced Reporting Format:

When patterns found, structure report for immediate use:

```
🔍 Found 5 relevant patterns for your task:

🔷 CORE PATTERN (used 12 times): Bash Error Handling with set -e
   When you need: Safe subprocess execution in bash scripts
   Apply this pattern:
   ```bash
   if result=$(command 2>&1 || true); then
       process_success "$result"
   else
       handle_failure "$result"
   fi
   ```
   
🔹 ESTABLISHED PATTERN (used 4 times): Cross-Platform Path Conversion
   When you need: WSL↔Windows file operations
   Apply: Use wslpath -w for Windows paths, wslpath -u for Unix paths

📋 Quick reference:
- For Docker memory: Use 4GB limit pattern (see line 127)
- For Python execution: Use fallback chain pattern (see line 195)
- Avoid: Direct cmd.exe calls (causes UNC warnings)
```

## Pattern Application Tracking:

When suggesting patterns, note which ones get used:
- Track pattern name and context
- Feed usage data back to repetition count
- Note any modifications needed for current context

## If no wisdom found:

```
⚠️ No PROJECT_WISDOM.md found in this project.

I'll proceed with first principles, but recommend:
1. Run /checkpoint and /wrap-session to capture discoveries
2. After a few sessions, run /clean-wisdom to distill patterns
3. This creates your project's skeleton exemplar library

Current approach: [Explain derivation strategy]
Alternative: Would you like me to check parent directories for inherited wisdom?
```

## Active Pattern Instantiation:

During implementation:
1. **Before writing new code**: Check if wisdom has relevant pattern
2. **When pattern exists**: Copy it exactly, then adapt minimally
3. **When pattern partially fits**: Note the adaptation for future wisdom
4. **After using pattern**: Track success/failure for evolution

## Pattern Categories to Check:

Based on current task, prioritize these pattern types:
- **Error Handling**: How this project handles failures
- **Configuration**: Project-specific settings and constants
- **Integration**: How tools/services connect
- **Performance**: Validated optimization patterns
- **Testing**: Project's test patterns and assertions
- **Anti-patterns**: What specifically doesn't work here

## Usage Notes:

- Patterns marked "empirically validated" are system invariants - never modify without regression evidence
- Evolution notes explain why current approach won over alternatives
- Failed alternatives prevent re-trying dead ends
- CORE PATTERNS should be your first choice when applicable