# GitHub Operations Reference

Common patterns for GitHub CLI operations across commands.

## Prerequisites Check
```bash
# Check GitHub CLI authentication
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ GitHub CLI not authenticated. Please run:"
    echo "gh auth login"
    echo ""
    echo "Then retry this command."
    exit 1
fi

# Check if in git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "❌ Not in a git repository"
    exit 1
fi
```

## Create Issue Pattern
```bash
# Basic issue creation
gh issue create \
  --title "TITLE" \
  --body "BODY" \
  --label "label1" \
  --label "label2"

# Capture issue number from output
issue_url=$(gh issue create --title "..." --body "..." 2>&1)
issue_number=$(echo "$issue_url" | grep -oE 'issues/[0-9]+' | cut -d'/' -f2)
```

## Common Labels
- `requirement` - For requirement tracking
- `priority:high`, `priority:medium`, `priority:low` - Priority levels
- `test`, `bug`, `enhancement`, `documentation` - Issue types

## Error Handling
- Always capture stderr: `2>&1`
- Check exit codes: `if [ $? -ne 0 ]; then`
- Provide clear error messages with recovery steps

## Output Format
```
✅ Created GitHub issue #XX for [description]

Priority: [priority]
Labels: [label1], [label2]

View issue: gh issue view XX
Edit issue: gh issue edit XX
```