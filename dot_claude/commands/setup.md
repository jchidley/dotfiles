Check if CLAUDE.md exists. If not, inform user: "No CLAUDE.md found. Run /init first."

If CLAUDE.md exists, append the following project standards:

## Development Standards

### Python Environment
- Package management: uv
- No requirements.txt needed
- Run scripts: `uv run <script.py>`
- Add packages: `uv add <package>`
- Dependencies in pyproject.toml

### Workflow
- Check TODO.md for tasks
- Mark completed items with [x]

### Quality Standards
- All tests must pass before completing tasks
- Linting must pass before completing tasks
- Run tests with: `uv run pytest`
- Run linting with: `uv run ruff check`

Output: "Project standards added to CLAUDE.md"