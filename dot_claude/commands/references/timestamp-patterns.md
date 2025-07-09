# Timestamp Patterns Reference

Standard timestamp generation and formatting across commands.

## Current Date/Time Format
```bash
# YYYY-MM-DD HH:MM format (for display)
timestamp=$(date +"%Y-%m-%d %H:%M")

# YYYYMMDD_HHMMSS format (for filenames)
file_timestamp=$(date +"%Y%m%d_%H%M%S")
```

## Common Uses

### Document Headers
```markdown
# Document Title
Created: YYYY-MM-DD HH:MM
```

### Filename Generation
```bash
# For wip-claude documents
filename="wip-claude/${file_timestamp}_description.md"

# For session documents
filename="sessions/SESSION_${file_timestamp}.md"
```

### HANDOFF.md Updates
```markdown
# Project: Name
Updated: YYYY-MM-DD HH:MM
```

## Platform Compatibility
- Use `date` command (POSIX compatible)
- Avoid GNU-specific options
- Always use double quotes around variables

## Examples
```bash
# Create timestamped file
echo "# Analysis" > "wip-claude/$(date +%Y%m%d_%H%M%S)_analysis.md"

# Update HANDOFF.md timestamp
sed -i "s/^Updated: .*/Updated: $(date +'%Y-%m-%d %H:%M')/" HANDOFF.md
```