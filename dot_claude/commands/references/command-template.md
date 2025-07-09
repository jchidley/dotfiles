# Command Template

Standard structure for all Claude commands.

## Template

```markdown
# /command-name

## Purpose
Brief one-line description of what this command does.

## Prerequisites
- Required tool or state
- Another prerequisite if needed
- Reference: See references/[pattern].md for details

## Process

### Step 1: Validate Input
- Check command arguments
- Validate format/requirements
- Error: "❌ Clear error message with example"

### Step 2: Main Operation
- Perform core functionality
- Use consistent indicators from references/output-indicators.md
- Reference shared patterns from references/

### Step 3: Output Results
```
✅ Success message with key information

Additional details:
- Item 1
- Item 2

Next steps: Command or action user can take
```

## Error Handling
- Missing file: "❌ File not found: [filename]"
- Invalid format: "❌ Invalid format. Expected: [example]"
- Tool failure: Show exact error from tool

## Examples

### Basic Usage
```
/command-name argument
```

### With Options
```
/command-name --option value
```

### Expected Output
```
✅ Command completed successfully
[Specific details about what was done]
```
```

## Key Principles

1. **Clarity**: Each step should have a clear purpose
2. **Consistency**: Use standard indicators and patterns
3. **Completeness**: Handle all error cases
4. **Conciseness**: Keep under 100 lines total
5. **References**: Link to shared patterns instead of duplicating

## Anti-Patterns to Avoid

- ❌ Embedding complex logic (extract to tools)
- ❌ Duplicating patterns (use references/)
- ❌ Mixed responsibilities (split into sub-commands)
- ❌ Vague error messages (be specific with recovery steps)
- ❌ Missing examples (always show usage)