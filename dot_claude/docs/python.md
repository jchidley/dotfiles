## Python Development Standards

### Tooling
- Use uv exclusively for package management (not pip, poetry, pipenv)
- Use uvx for running ephemeral tools and one-off commands
- Use ruff for linting and formatting (not black, flake8, isort)
- Configure everything in pyproject.toml

### Essential Commands
```bash
uv init project-name       # New project
uv add package-name        # Add dependency
uv run command             # Run in project environment
uv run pytest              # Run tests
uvx tool-name              # Run tools without installing
ruff check .               # Lint
ruff format .              # Format
ruff check --fix .         # Auto-fix issues
```

### Project Structure
- Always use pyproject.toml (run `uv init` if missing)
- Prefer src/ layout for packages
- Use `__init__.py` for proper packaging

### Error Handling
- Return Optional[T] or Union[T, Error] instead of raising exceptions
- Use Result pattern: `def parse() -> Union[ParsedData, ParseError]`
- Make side effects explicit: `read_file()`, `write_database()`
- Avoid bare exceptions

### Testing
- Write tests first (TDD)
- Use pytest exclusively with `uv run pytest`
- No mock implementations - use real data/APIs
- Test output must be pristine to pass

### Data Design Patterns
- Use @dataclass(frozen=True) for immutable records
- Prefer Enum over string constants
- Use NewType pattern: UserId(int) instead of bare integers
- Batch operations over individual processing

*For complete uv usage guide, see @~/.claude/docs/advanced/uv-complete-guide.md*
*For Python to Rust migration, see @~/.claude/docs/advanced/python-to-rust-migration.md*