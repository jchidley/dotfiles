# /wisdom

Load and apply project-specific patterns from PROJECT_WISDOM.md to guide implementation.

When user runs `/wisdom`, read PROJECT_WISDOM.md and internalize all patterns for the current project, similar to how `/standards` loads CLAUDE.md files.

IMPORTANT: Change to project root directory before file operations.
Use the working directory from the environment info as the project root.

## Loading Process:

1. **Read PROJECT_WISDOM.md** from current project directory
   - Load all CORE PATTERNS (6+ uses) 
   - Load all ESTABLISHED PATTERNS (3-5 uses)
   - Load all EMERGING PATTERNS (1-2 uses)
   - Note any anti-patterns and failed approaches

2. **If no PROJECT_WISDOM.md exists**:
   - Check CURRENT_PROJECT_WISDOM.md as fallback
   - Report that no refined wisdom exists yet
   - Suggest running /clean-wisdom after accumulating sessions

3. **Apply patterns throughout session**:
   - Use these patterns as primary reference for implementation
   - When writing code, check if a pattern exists before creating new approach
   - Apply patterns exactly as documented, adapting only when necessary
   - Respect "empirically validated" patterns as system invariants

## Report Format:

```
📚 Loading project wisdom from PROJECT_WISDOM.md...

Found patterns to guide implementation:
- 🔷 X CORE PATTERNS (highest priority)
- 🔹 Y ESTABLISHED PATTERNS (proven approaches)
- 🔸 Z EMERGING PATTERNS (promising techniques)

Key patterns loaded:
- Bash Error Handling: Safe arithmetic and subprocess patterns
- Python Execution: Fallback chain for cross-environment compatibility
- Progress Messages: Always use stderr for progress output
- [List other major patterns by category]

Anti-patterns to avoid:
- [List documented failures and what not to do]

✅ Project wisdom loaded. I'll apply these patterns throughout our session.
```

## Behavioral Impact:

After loading wisdom, I will:
1. **Prioritize documented patterns** over general best practices
2. **Use exact code snippets** from patterns when applicable
3. **Avoid all documented anti-patterns** and failed approaches
4. **Respect empirical validations** - never change "magic numbers" without evidence
5. **Follow evolution history** - use the most recent validated approach

## Pattern Application:

When implementing any feature:
- First check: Does PROJECT_WISDOM.md have a pattern for this?
- If yes: Use that pattern exactly, mention which pattern I'm applying
- If partial match: Adapt minimally, note the adaptation
- If no match: Proceed with first principles, document new discovery

## Integration with Other Commands:

- Works with `/standards`: Standards define rules, wisdom provides patterns
- Complements `/checkpoint`: Captures new patterns for future wisdom
- Feeds `/clean-wisdom`: Usage tracking helps refine pattern emphasis