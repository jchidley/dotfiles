## Source Control Standards

### Tool Preference
1. **Primary**: GitHub CLI (`gh`) for all GitHub operations
2. **Fallback**: Git for local operations and when gh unavailable

### GitHub CLI Workflow
```bash
# Pull requests
gh pr create --title "feat: description" --body "details"
gh pr list
gh pr view 123
gh pr merge 123

# Issues
gh issue create --title "bug: description"
gh issue list --label bug
gh issue close 123

# Repos
gh repo clone owner/repo
gh repo view --web
```

### Git Workflow (Local)
```bash
git add -A                      # Stage changes
git commit -m "feat: description"  # Commit
git push                        # Push to remote
git status                      # Check status
```

### Commit Message Format
- Type: feat|fix|docs|style|refactor|test|chore
- Scope: optional, in parentheses
- Description: imperative mood, present tense
- Footer: Co-Authored-By: Claude <noreply@anthropic.com>

Example: `feat(auth): add OAuth2 integration`