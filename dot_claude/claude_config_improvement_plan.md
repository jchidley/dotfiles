# Claude Configuration Improvement Plan

## Executive Summary
This plan addresses conflicts, inconsistencies, and redundancies found across Claude configuration files, proposing a consolidated and improved structure.

## Key Issues Identified

### 1. Source Control Conflict
- **Issue**: Instructions say "prefer JJ" but user doesn't have JJ installed
- **Resolution**: Update to prefer GitHub CLI (gh) with git as fallback

### 2. Python Documentation Fragmentation  
- **Issue**: Python/uv info spread across 3 files with duplication
- **Resolution**: Consolidate into single python.md with essentials only

### 3. Overly Detailed Rust/PyO3 Content
- **Issue**: 113 lines of PyO3 conversion guide in main config
- **Resolution**: Move to separate advanced/rust-migration.md

### 4. Missing Core Topics
- **Issue**: No guidance on logging, security, APIs, databases
- **Resolution**: Add new sections for these essentials

## Proposed New Structure

### 1. Main CLAUDE.md (Simplified Core)
```
CLAUDE.md (50-60 lines max)
├── Identity & Tone (5 lines)
├── Core Principles (10 lines)
│   ├── Simplicity over cleverness
│   ├── Minimal changes
│   ├── No assumptions
│   └── Testing requirements
├── File Management Rules (10 lines)
│   ├── Never create unless necessary
│   ├── ABOUTME: comment requirement
│   └── No mock implementations
├── Workflow Standards (10 lines)
│   ├── Ask before major changes
│   ├── Regression testing
│   └── Git commit format
└── Technology References (5 lines)
    ├── @docs/python.md
    ├── @docs/javascript.md
    └── @docs/source-control.md
```

### 2. Language-Specific Docs
```
docs/
├── python.md (30-40 lines)
│   ├── Tooling (uv only, no pip)
│   ├── Essential commands (10 lines)
│   ├── Project structure
│   ├── Testing with pytest
│   └── Error handling patterns
├── javascript.md (new)
├── rust.md (new)
└── shell.md (new)
```

### 3. Advanced Topics (Optional Reading)
```
docs/advanced/
├── python-to-rust-migration.md (current PyO3 content)
├── performance-optimization.md
└── uv-complete-guide.md (current using-uv.md)
```

### 4. Missing Topics to Add
```
docs/
├── security.md
│   ├── Secret handling
│   ├── Input validation
│   └── Dependency management
├── logging.md
│   ├── Log levels
│   ├── Format standards
│   └── No sensitive data
├── api-design.md
│   ├── RESTful principles
│   ├── Error responses
│   └── Versioning
└── database.md
    ├── Query patterns
    ├── Migration approach
    └── Connection handling
```

## Specific Consolidation Actions

### 1. Merge Python Documentation
**Current**: 
- Global CLAUDE.md (Python section): 15 lines
- python.md: 7 lines  
- using-uv.md: 185 lines

**Proposed python.md** (35 lines):
```markdown
## Python Development Standards

### Tooling
- Use uv exclusively for package management (not pip, poetry, pipenv)
- Use ruff for linting and formatting (not black, flake8, isort)
- Configure everything in pyproject.toml

### Essential Commands
```bash
uv init project-name       # New project
uv add package-name       # Add dependency
uv run pytest            # Run tests
uv run ruff check .      # Lint
uv run ruff format .     # Format
```

### Project Structure
- Always use pyproject.toml (run `uv init` if missing)
- Prefer src/ layout for packages
- Use `__init__.py` for proper packaging

### Error Handling
- Return Optional[T] or Result types
- Avoid bare exceptions
- Use explicit error types

### Testing
- Write tests first (TDD)
- Use pytest exclusively
- No mock implementations

*For advanced uv usage, see docs/advanced/uv-complete-guide.md*
```

### 2. Clarify Source Control
**New source-control.md**:
```markdown
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
```

### 3. Simplify Main CLAUDE.md
Remove:
- Detailed Python tooling (→ python.md)
- PyO3/Rust migration guide (→ advanced/python-to-rust-migration.md)
- Redundant internal references
- Overly specific examples

Add:
- Clear section headers
- Bullet points instead of paragraphs
- Links to detailed docs only when needed

### 4. Fix Project vs Global Confusion
- Move `/home/jack/CLAUDE.md` to actual chezmoi project root
- Keep `/home/jack/.claude/CLAUDE.md` as global config
- Add header to each file clarifying scope:
  ```markdown
  # CLAUDE.md - Global Configuration
  # Applies to all projects unless overridden
  ```

## Implementation Priority

### Phase 1: Core Cleanup (Immediate)
1. Consolidate Python docs into single file
2. Extract Rust/PyO3 content to advanced/
3. Fix source control documentation
4. Remove all duplication

### Phase 2: Structure (Next Session)
1. Reorganize main CLAUDE.md
2. Create consistent formatting
3. Add missing section headers
4. Establish clear hierarchy

### Phase 3: Additions (Future)
1. Add security.md
2. Add logging.md  
3. Add api-design.md
4. Add database.md

## Success Metrics
- Main CLAUDE.md under 100 lines
- No duplicate commands across files
- Clear decision trees for tool choices
- All conflicts resolved
- Missing topics documented

## Next Steps
1. Review and approve this plan
2. Create backup of current configs
3. Implement Phase 1 consolidations
4. Test with real development tasks
5. Iterate based on usage

---
*Generated: 2025-01-22*