# Git Operations Reference

Common git operation patterns across commands.

## Status Checks

### Check if in Git Repository
```bash
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "❌ Not in a git repository"
    exit 1
fi
```

### Get Current Branch
```bash
current_branch=$(git branch --show-current)
```

### Check for Changes
```bash
# Check if working tree is clean
if git diff --quiet && git diff --cached --quiet; then
    changes="No"
else
    changes="Yes"
fi

# Count changed files
changed_files=$(git status --porcelain | wc -l)
```

## Common Operations

### Recent Commits
```bash
# Last 5 commits, one line each
git log --oneline -5

# Last 10 commits with dates
git log --pretty=format:"%h %ad %s" --date=short -10
```

### Project Information
```bash
# Get project name from remote
project_name=$(git remote get-url origin 2>/dev/null | sed 's/.*\/\([^.]*\).*/\1/')

# Fallback to directory name
if [ -z "$project_name" ]; then
    project_name=$(basename "$PWD")
fi
```

### File Operations
```bash
# Add all changes
git add -A

# Add specific file
git add "$filename"

# Check if file is tracked
if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
    echo "File is tracked"
fi
```

## Output Formats

### Status Summary
```
Branch: main | Changes: Yes (3 files)
```

### Commit List
```
## Recent Commits
35025c2 fix: improve start command clarity
de6b492 feat: add Claude hooks support
c12386c enhance: add cross-project analysis
```

## Error Handling

- Repository check should be done early
- Use `2>/dev/null` to suppress git's stderr when checking
- Provide fallbacks for operations that might fail
- Always quote variables that might contain spaces