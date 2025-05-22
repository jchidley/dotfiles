## Source Control

- Primary tool: GitHub CLI (`gh`) for all GitHub operations (PRs, issues, repo management)
- Fallback tool: Git for local version control when gh is not applicable
- Commit messages should be concise and descriptive
- Commit messages should follow the conventional commit format
- Commit messages should be written in the imperative mood
- Commit messages should be written in the present tense

### Common gh commands:
```bash
gh pr create --title "feat: add new feature" --body "Description"
gh pr list
gh issue create --title "bug: fix issue"
gh repo clone owner/repo
```
