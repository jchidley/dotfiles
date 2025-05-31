# CLAUDE.md - Development Standards Hub

This file provides comprehensive development standards and guidance for Claude Code (claude.ai/code) when working on any development project.

## 🚨 Language Selection (PRIMARY DECISION POINT)

### Language Hierarchy - READ THIS FIRST
1. **Bash** (PRIMARY): First choice for system tasks and automation
   - Best for: Quick scripts, file operations, system config, glue scripts
   - Use bash first unless complexity demands additional tooling
   - Examples: PDF reading (pdftotext), file search (find/grep), API calls (curl), data extraction (awk/sed)
   - Avoid for: Complex data structures, cross-platform needs

2. **Bash + Rust helpers**: When bash needs performance-critical components
   - Best for: Scripts that need fast data processing or complex calculations
   - Create small rust utilities that bash can pipe to/from
   - Example: bash script orchestrating rust tools for parsing, filtering, transforming

3. **Rust**: When the entire solution needs to be a robust program
   - Best for: Full CLIs, servers, cross-platform tools, distributable binaries
   - Use when: Complex logic, error handling, or type safety throughout
   - Ideal for: Tools that need long-term maintenance or distribution

4. **Python**: Data analysis, scripting, or when specific libraries are needed
   - Best for: ML/AI tasks, data science, quick prototypes, API clients
   - Use when: NumPy/Pandas/PyTorch ecosystem is beneficial

5. **TypeScript**: Web frontends and when JavaScript ecosystem is required
   - Best for: Web apps, Electron/Tauri frontends, Node.js servers
   - Avoid for: System tools or performance-critical applications

### Bash-First Decision Process
1. Can the task be done with standard Unix tools? → **Use bash**
2. Does it need specific language libraries (NumPy, React, etc.)? → Use that language
3. Does it need to be distributed as a binary? → Use Rust
4. Is it a one-off data analysis? → Consider Python with uvx
5. **Default: Start with bash, refactor if needed**

## Bash Script Standards

### Testing and Debugging Requirements
All bash scripts MUST include:

1. **Error Handling**
   ```bash
   set -euo pipefail  # Exit on error, undefined vars, pipe failures
   IFS=$'\n\t'        # Safe Internal Field Separator
   ```

2. **Debug Mode Support**
   ```bash
   # Enable with DEBUG=1 or --debug flag
   DEBUG="${DEBUG:-0}"
   [[ "$DEBUG" == "1" ]] && set -x  # Print commands as executed
   ```

3. **Validation Functions**
   ```bash
   # Command availability check
   command_exists() {
       command -v "$1" >/dev/null 2>&1
   }
   
   # Dependency verification
   check_dependencies() {
       local deps=("$@")
       for cmd in "${deps[@]}"; do
           command_exists "$cmd" || die "Missing dependency: $cmd"
       done
   }
   ```

4. **Error Reporting**
   ```bash
   die() {
       echo "ERROR: $*" >&2
       exit 1
   }
   
   warn() {
       echo "WARNING: $*" >&2
   }
   ```

5. **Testing Support**
   ```bash
   # Self-test mode with --test flag
   if [[ "${1:-}" == "--test" ]]; then
       run_tests
       exit $?
   fi
   ```

### Script Template
```bash
#!/usr/bin/env bash
# ABOUTME: Brief description of script purpose
# Usage: script.sh [options] <args>

set -euo pipefail
IFS=$'\n\t'

# Debug mode
DEBUG="${DEBUG:-0}"
[[ "$DEBUG" == "1" ]] && set -x

# Script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Error handling
die() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARNING: $*" >&2; }

# Dependency check
check_dependencies() {
    local deps=("$@")
    for cmd in "${deps[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || die "Missing: $cmd"
    done
}

# Main function
main() {
    check_dependencies "required_command1" "required_command2"
    
    # Script logic here
}

# Test mode
if [[ "${1:-}" == "--test" ]]; then
    # Run tests
    echo "Running tests..."
    # Test implementations
    exit 0
fi

# Execute main
main "$@"
```

### Testing Requirements
- **Static Analysis**: Use `shellcheck` for all scripts (non-negotiable)
- **Unit Testing**: Use `bats-core` as the primary testing framework
- **Test Coverage**: All non-trivial scripts MUST have accompanying tests
- **Dry Run**: Provide --dry-run option for destructive operations
- **Self-Test**: Include --test flag for basic validation

### Bash Testing with Bats

#### Installation
```bash
# Debian/Ubuntu
sudo apt-get install bats

# Using npm
npm install -g bats

# From source (recommended for latest features)
git clone https://github.com/bats-core/bats-core.git
cd bats-core && ./install.sh /usr/local
```

#### Test File Structure
```bash
#!/usr/bin/env bats
# test_script.bats

# Load the script to test
setup() {
    # Run before each test
    export TEST_DIR="$(mktemp -d)"
    source "${BATS_TEST_DIRNAME}/../script.sh"
}

teardown() {
    # Run after each test
    rm -rf "$TEST_DIR"
}

@test "function validates input correctly" {
    run validate_input "valid@email.com"
    [ "$status" -eq 0 ]
    [ "$output" = "Valid email" ]
}

@test "function rejects invalid input" {
    run validate_input "invalid.email"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid" ]]
}

@test "handles missing files gracefully" {
    run process_file "/nonexistent"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Error: File not found" ]
}
```

#### Testing Best Practices

1. **Test Organization**
   ```bash
   project/
   ├── scripts/
   │   ├── deploy.sh
   │   └── backup.sh
   └── tests/
       ├── test_deploy.bats
       └── test_backup.bats
   ```

2. **Mocking External Commands**
   ```bash
   # Mock dangerous or external commands
   setup() {
       # Override command in test
       curl() {
           echo "MOCK: curl $*"
           return 0
       }
       export -f curl
   }
   
   @test "api call uses correct endpoint" {
       run call_api "data"
       [[ "$output" =~ "MOCK: curl.*https://api.example.com" ]]
   }
   ```

3. **Testing Error Conditions**
   ```bash
   @test "script exits on missing dependencies" {
       # Mock command_exists to return false
       command_exists() { return 1; }
       export -f command_exists
       
       run main
       [ "$status" -eq 1 ]
       [[ "$output" =~ "Missing dependency" ]]
   }
   ```

4. **Testing with Fixtures**
   ```bash
   setup() {
       # Create test data
       cat > "$TEST_DIR/config.json" << EOF
   {
       "key": "value",
       "debug": true
   }
   EOF
   }
   
   @test "parses config correctly" {
       run parse_config "$TEST_DIR/config.json"
       [ "$status" -eq 0 ]
       [[ "$output" =~ "debug mode enabled" ]]
   }
   ```

#### CI/CD Integration

**GitHub Actions Example:**
```yaml
name: Bash Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install bats
        run: |
          sudo apt-get update
          sudo apt-get install -y bats
      - name: Run tests
        run: bats tests/*.bats
      - name: Shellcheck
        run: find . -name "*.sh" -type f | xargs shellcheck
```

#### Common Testing Patterns

1. **Skip Tests Conditionally**
   ```bash
   @test "requires root privileges" {
       [ "$EUID" -ne 0 ] && skip "requires root"
       run admin_function
       [ "$status" -eq 0 ]
   }
   ```

2. **Test Timeout Handling**
   ```bash
   @test "completes within time limit" {
       run timeout 5 ./long_running_script.sh
       [ "$status" -eq 0 ]
   }
   ```

3. **Debug Mode Testing**
   ```bash
   @test "debug mode produces verbose output" {
       DEBUG=1 run ./script.sh
       [[ "$output" =~ "DEBUG:" ]]
   }
   ```

#### Common Pitfalls to Avoid

1. **Variable Scope in Subshells**
   ```bash
   # WRONG: Variable changes in pipes are lost
   count=0
   cat file | while read line; do ((count++)); done
   echo $count  # Still 0!
   
   # RIGHT: Avoid subshell
   count=0
   while read line; do ((count++)); done < file
   echo $count  # Correct count
   ```

2. **Word Splitting Issues**
   ```bash
   # WRONG: Unquoted variables split on spaces
   file="my document.txt"
   rm $file  # Tries to remove "my" and "document.txt"
   
   # RIGHT: Always quote variables
   rm "$file"
   
   # Test for this:
   @test "handles spaces in filenames" {
       touch "$TEST_DIR/file with spaces.txt"
       run process_file "$TEST_DIR/file with spaces.txt"
       [ "$status" -eq 0 ]
   }
   ```

3. **Exit Code Propagation**
   ```bash
   # WRONG: Pipeline hides failures
   false | true
   echo $?  # Shows 0, not 1
   
   # RIGHT: Use pipefail
   set -o pipefail
   false | true
   echo $?  # Shows 1
   ```

4. **Cleanup on Exit**
   ```bash
   # WRONG: Temp files left behind on error
   temp=$(mktemp)
   # Script fails here...
   
   # RIGHT: Use trap for cleanup
   temp=$(mktemp)
   trap "rm -f $temp" EXIT
   # Cleanup happens even on error
   ```

## STOP - CHECK BEFORE STARTING ANY TASK
1. **System task? → Start with bash/Unix tools** (grep, awk, curl, jq, pdftotext, etc.)
2. **Default to simplest solution** - If bash can do it, use bash

## Repository Purpose

General tooling repository for Linux utilities, MCP servers/clients, and development scripts. This repository serves as the central hub for all development standards and practices.

## Repository Structure

- `setup_*.sh` - Installation scripts
- `scripts/` - Shell scripts and automation
- `rust/` - Rust tools (preferred for complex/cross-platform tools)
- `python/` - Python scripts (for data/ML or specific libraries)
- `typescript/` - TypeScript tools (for web/JS ecosystem needs)
- `docs/` - Integration reports and documentation

## Core Development Principles

### Code Quality
- Prefer simple, maintainable solutions over clever ones
- Make smallest reasonable changes
- Match existing code style within files
- Ask permission before reimplementing from scratch

### Documentation
- Never remove comments unless provably false
- Start files with 2-line ABOUTME: comment
- Keep comments evergreen (describe current state)
- Only create docs when explicitly requested

### Changes & Commits
- Never make unrelated changes to current task
- Never use --no-verify when committing
- Never name things as 'improved', 'new', 'enhanced'
- Check conversation history to prevent regressions

### Proactive Behavior Guidelines
- DO: Run tests, linting, type checking after changes
- DO: Use search tools extensively to understand context
- DO: Ask clarifying questions when requirements are unclear

## Testing Standards

### TDD Process
1. Write failing test first
2. Write minimal code to pass
3. Refactor while keeping tests green
4. Repeat for each feature/bugfix

### Requirements
- Tests MUST cover functionality
- Test output MUST be pristine
- Never ignore test/system output
- Never skip test types without explicit authorization
- No mock implementations - use real data/APIs

## Visual & Multi-Device Applications

- **Web Apps**: TypeScript with modern frameworks (SvelteKit, Next.js, or vanilla with Vite)
- **Desktop Apps**: Tauri (Rust backend + web frontend) for cross-platform native apps
- **Mobile/PWA**: Progressive Web Apps for multi-device access without app stores
- **CLI with TUI**: Rust with ratatui for rich terminal interfaces
- **Data Visualization**: Python with Plotly/Dash for interactive dashboards

## Dependencies & Tool Execution

- Bash: No package manager needed, ensure shebang specifies bash when needed
  - Use shellcheck for linting, document required commands
- Rust: Use Cargo.toml, prefer workspace for multiple tools
  - `cargo run` for development, compiled binaries for distribution
  - Consider cross-compilation for multi-platform distribution
- Python: Use uv/uvx for package management and script execution
  - `uvx` for one-off execution, `uv run` for project scripts
  - Create `pyproject.toml` for proper dependency management
- TypeScript: Choose runtime based on needs
  - **Bun**: Fast all-in-one for scripts and tools (still maturing)
  - **Node.js + pnpm**: Stable choice for production web apps
  - **Deno**: Built-in TypeScript, security-first, good for isolated tools
  - Use `tsx` for quick TypeScript execution in Node.js environment

## Installation Standards

- Install executables to `~/.local/bin/`
- Install libraries/shared resources to `~/.local/share/<tool-name>/`
- Never install directly from working directory - always copy/build to `~/.local`
- Source files stay in project subdirectories (e.g., `rust/`, `typescript/`, `python/`)
- Provide uninstall instructions or scripts

## Data Storage

- Use SQLite for persistent data (single-file, portable, no server)
- Store databases in `~/.local/share/<tool-name>/`
- Include schema migrations when needed

## Environment

- WSL: Debian (primary) and Alpine Linux (utility)
- Examples should reflect Debian as primary

## MCP Development

### Key Concepts
- JSON-RPC 2.0 over stdio (stdin/stdout)
- Required methods: `initialize`, `initialized`, `tools/list`, tool handlers
- Config: `~/.claude.json` (global), project settings can override

### Resources
- Spec: https://spec.modelcontextprotocol.io/
- Examples: https://github.com/modelcontextprotocol/servers/tree/main/src
- Related: `/home/jack/mcp-fd-server` (Rust implementation)

### Documentation Format
When documenting MCP integrations, include:
- Summary of attempts
- What worked/didn't work
- Root cause analysis
- Technical details with code snippets

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

## Build Tools and Task Runners

### Task Runner Standard: mask

Use **mask** for project task automation across all projects.

#### Why mask?
- Human-readable markdown format (`maskfile.md`)
- Cross-platform support (including Windows)
- Language-agnostic (supports bash, python, node, ruby, php)
- Self-documenting with built-in help generation
- Simpler than Makefiles, more portable than npm scripts

#### Basic Usage
```bash
mask <task>           # Run a task
mask --help          # Show available tasks
mask <task> --help   # Show help for specific task
```

#### Task Definition Format
Tasks are defined in `maskfile.md` using markdown headings:

```markdown
## build
> Build the project for release

~~~bash
cargo build --release
~~~

## test (filter)
> Run tests with optional filter
>
> **POSITIONAL ARGUMENTS**
> * filter - Test name filter (optional)

~~~bash
cargo test $filter
~~~

## lint

> Run all linting checks

~~~bash
set -e  # Exit on first error
cargo clippy -- -D warnings
cargo fmt -- --check
~~~
```

#### Best Practices
1. Always include a description after the task name using `>`
2. Document positional and optional arguments clearly
3. Use `set -e` in bash scripts to fail fast on errors
4. Group related tasks with subcommands (using heading levels)
5. Keep maskfile.md at project root for discoverability

### Build Tool Selection

#### Rust Projects
- Use Cargo with workspace for multiple tools
- Define common tasks in maskfile.md (test, lint, install)
- Consider cargo-watch for development

#### Python Projects  
- Use `uv` and `pyproject.toml` for dependency management
- Define tasks in maskfile.md instead of scripts section
- Use `uv run` for task execution when dependencies needed

#### TypeScript/JavaScript Projects
- Use mask instead of npm scripts for consistency
- Keep package.json scripts minimal (just for ecosystem compatibility)
- Choose appropriate runtime (bun, node+pnpm, deno) based on needs

#### Cross-Language Projects
- Single maskfile.md at root to coordinate all languages
- Use subcommands to organize by language/component

## Logging Standards

### Log Levels
- ERROR: System failures requiring attention
- WARNING: Recoverable issues
- INFO: Important state changes
- DEBUG: Development troubleshooting only

### Format Requirements
- Include timestamp, level, and context
- Use structured logging when possible
- Keep messages concise and actionable

### Security
- Never log passwords, tokens, or PII
- Sanitize user data before logging
- Consider log retention policies

## Security Standards

### Secret Management
- Never hardcode secrets, keys, or passwords
- Use environment variables or secure vaults
- Never log sensitive information
- Exclude .env files from version control

### Input Validation
- Validate all user inputs
- Use parameterized queries for databases
- Sanitize data before rendering
- Implement proper rate limiting

### Dependencies
- Keep dependencies updated
- Review security advisories
- Use lock files for reproducible builds
- Audit dependencies before adding

## UV Field Manual (Quick Reference)

### Daily Workflows

#### Project ("cargo‑style") Flow
```bash
uv init myproj                     # create pyproject.toml + .venv
cd myproj
uv add ruff pytest httpx           # fast resolver + lock update
uv run pytest -q                   # run tests in project venv
uv lock                            # refresh uv.lock (if needed)
uv sync --locked                   # reproducible install (CI‑safe)
```

#### Script‑Centric Flow (PEP 723)
```bash
echo 'print("hi")' > hello.py
uv run hello.py                    # zero‑dep script, auto‑env
uv add --script hello.py rich      # embeds dep metadata
uv run --with rich hello.py        # transient deps, no state
```

#### CLI Tools (pipx Replacement)
```bash
uvx ruff check .                   # ephemeral run
uv tool install ruff               # user‑wide persistent install
uv tool list                       # audit installed CLIs
uv tool update --all               # keep them fresh
```

#### Python Version Management
```bash
uv python install 3.10 3.11 3.12
uv python pin 3.12                 # writes .python-version
uv run --python 3.10 script.py
```

### Performance‑Tuning

| Env Var                   | Purpose                 | Typical Value |
| ------------------------- | ----------------------- | ------------- |
| `UV_CONCURRENT_DOWNLOADS` | saturate fat pipes      | `16` or `32`  |
| `UV_CONCURRENT_INSTALLS`  | parallel wheel installs | `CPU_CORES`   |
| `UV_OFFLINE`              | enforce cache‑only mode | `1`           |
| `UV_INDEX_URL`            | internal mirror         | `https://…`   |

### CI/CD Recipes

#### GitHub Actions
```yaml
# .github/workflows/test.yml
name: tests
on: [push]
jobs:
  pytest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5       # installs uv, restores cache
      - run: uv python install            # obey .python-version
      - run: uv sync --locked             # restore env
      - run: uv run pytest -q
```

#### Docker
```dockerfile
FROM ghcr.io/astral-sh/uv:0.7.4 AS uv
FROM python:3.12-slim

COPY --from=uv /usr/local/bin/uv /usr/local/bin/uv
COPY pyproject.toml uv.lock /app/
WORKDIR /app
RUN uv sync --production --locked
COPY . /app
CMD ["uv", "run", "python", "-m", "myapp"]
```

### Migration Matrix

| Legacy Tool / Concept | One‑Shot Replacement        | Notes                 |
| --------------------- | --------------------------- | --------------------- |
| `python -m venv`      | `uv venv`                   | 10× faster create     |
| `pip install`         | `uv pip install`            | same flags            |
| `pip-tools compile`   | `uv pip compile` (implicit) | via `uv lock`         |
| `pipx run`            | `uvx` / `uv tool run`       | no global Python req. |
| `poetry add`          | `uv add`                    | pyproject native      |
| `pyenv install`       | `uv python install`         | cached tarballs       |

## Available Slash Commands

Claude Code supports custom slash commands for common workflows. Commands are stored in `~/.claude/commands/`.

### Common Commands
- `/plan` - Create detailed project blueprint with plan.md and todo.md
- `/plan-tdd` - Plan with TDD approach, starting with tests
- `/plan-gh` - Plan with GitHub issues integration
- `/do-todo` - Execute tasks from todo.md file
- `/do-issues` - Work through issues in issues.md
- `/gh-issue` - Create GitHub issue from current context
- `/make-github-issues` - Convert local issues to GitHub
- `/log` - Document current session
- `/security-review` - Review code for security issues
- `/find-missing-tests` - Identify untested code

### Usage
Simply type the slash command in Claude Code to invoke the workflow. Each command contains specific instructions for that workflow pattern.

To see all available commands: `ls ~/.claude/commands/`

## Python to Rust Migration Guide (PyO3)

### Design Phase

#### Core Architecture Principles
- Design around data transformation pipelines rather than stateful objects
- Separate pure computation (future Rust) from I/O and glue code (stays Python)
- Use algebraic data types - enums and structs, not inheritance hierarchies
- Plan ownership boundaries - who owns what data and when it's transferred

#### Data Design for Rust Compatibility
- Use @dataclass(frozen=True) for immutable records that map to Rust structs
- Prefer Enum over string constants (maps to Rust enums)
- Design collections as Vec<T> equivalents - avoid nested dicts and mixed types
- Use NewType pattern: UserId(int) instead of bare integers
- Structure data as trees, not graphs - avoid circular references entirely

#### When to Convert to Rust Decision Tree
- CPU-intensive loops with numeric computation → High Priority
- Data parsing/validation with complex rules → High Priority  
- I/O bound operations → Stay in Python
- Simple CRUD operations → Stay in Python
- Hot path called >10k times/second → Consider conversion
- Memory usage >100MB for data structures → Consider conversion

### Conversion Phase

#### PyO3 Conversion Process
- Start with pure functions that take/return simple types (int, str, bytes)
- Create Rust module: cargo init --lib, add pyo3 to Cargo.toml with extension-module
- Use #[pyfunction] for standalone functions, #[pyclass] for stateful objects
- Implement From/Into traits for complex type conversions
- Use PyResult<T> for all fallible operations - maps to Python exceptions

#### Build Integration
- Use maturin for building PyO3 extensions: uv add --dev maturin
- Structure: src/lib.rs (Rust), python/yourmodule/ (Python wrapper)
- Build with: uv run maturin develop (for development) or maturin build (for release)

#### Common Mistakes to Avoid
- Don't hold Python objects across await points in async Rust
- Always use py.allow_threads() for CPU work to release GIL
- Use PyResult, not unwrap() - Python expects exceptions not panics
- Clone data at boundaries rather than sharing references
- Don't use Arc<Mutex<>> for Python-visible state - use PyCell instead