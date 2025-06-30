# CLAUDE.md - Development Standards Hub

This file provides behavioral instructions for Claude Code (claude.ai/code) when working on any development project. For detailed reference material, see the docs/ directory.

## 🚨 Language Selection (Behavioral Rules)

### Primary Rule: ALWAYS Start with Bash
1. Can the task be done with standard Unix tools? → **Use bash**
2. Does it need specific language libraries? → Use that language
3. Does it need to be distributed as a binary? → Use Rust
4. Is it a one-off data analysis? → Consider Python with uvx
5. **Default: Start with bash, refactor if needed**

### Language Escalation
- Bash struggles with performance → Add Rust helpers (keep bash orchestration)
- Need complex data structures → Move to Python or Rust
- Complexity creep is technical debt → Resist moving to "fancier" language

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

## Development Operational Modes

In addition to system-level Planning/Research modes:

### Implementation Mode
**Triggers**: "implement", "fix", "create", "write" (with approved plan or clear scope)
**Actions**: 
- Follow approved plan exactly
- Work → Check Plan → Work → Check Plan cycle
- Flag ANY deviation immediately
- Complete ALL items in plan
**Exit**: Plan complete or user requests mode change

### Refactoring Mode
**Triggers**: "refactor"
**Actions**: 
- Create mechanical refactoring plan first
- Follow REFACTORING_RULES.md exactly
- ZERO behavior changes allowed
- Tests must stay green
**Exit**: Refactoring complete with unchanged behavior

## Plan Execution Discipline

During Implementation Mode:
- Reference plan constantly
- After each function/file: check alignment with plan
- On deviation: "Plan says X, found Y. Should I proceed with X or adjust?"
- Complete ALL plan items before considering done
- No "while I'm here" additions

## Empirical Development Principle

When empirical data contradicts theory, data wins:
- Test actual behavior, don't trust documentation
- Validate with real-world data before claiming improvements
- Use regression tests as source of truth
- Projects may define "System Invariants" based on empirical validation

### System Invariants Pattern
When a project defines constants as "System Invariants - Never Modify":
- These are empirically validated values from real data
- Changing them requires regression test evidence
- Always ask user before modifying any invariant
- Document why if you must preserve "magic numbers"

### Regression Evidence Requirements
Before changing behavior that affects outcomes:
1. Run existing regression/golden tests
2. Document current baseline metrics
3. Make your change
4. Run tests again and compare
5. Only claim "improvement" if metrics improve

Never use words like "improved", "optimized", or "enhanced" without regression evidence.

## Testing Discipline - The OCR 0% Lesson

**Critical Case Study**: OCR module had property tests, snapshot tests, integration tests, fuzz tests. Mutation testing revealed **0% effectiveness** - none verified correctness.

### Mutation Testing Requirements

**Process for EVERY test**:
1. Write 2-3 unit tests with concrete value assertions
2. Run mutation testing on JUST that function immediately
3. If mutations survive, fix tests before proceeding
4. Never accept "it works" without mutation verification

**Red Flags - Your Tests Are Ineffective**:
- Only checking structure: `assert(result.isValid)`
- Only checking non-null: `assert(result !== null)`
- No concrete value assertions
- Property tests with no property checks
- Snapshot tests as primary verification

### Testing Requirements
- Tests MUST verify actual values, not just structure
- Tests MUST catch logic/calculation errors
- Mutation score >75% for critical code
- Test output MUST be pristine
- Never skip test types without explicit authorization

### Empirical Validation
- Golden tests/regression tests are truth for behavior
- Run before and after ANY behavioral change
- Performance claims need benchmark evidence
- Accuracy claims need test suite validation

## Refactoring Discipline

When user asks for refactoring (not new features or bug fixes):
1. **STOP and confirm**: "This is a refactoring task - I must preserve exact behavior. Proceeding with mechanical refactoring process."
2. **Never combine**: Refactoring and improvements are separate tasks
3. **Test specification**: Tests define behavior - if tests fail, refactoring failed
4. **Mechanical process**: Follow exact steps, no deviations

### Mechanical Refactoring Processes

**Move Function Between Files**:
1. Copy entire source file to new location
2. Delete everything except function to move
3. Update imports/exports only
4. Never modify the function itself

**Extract Variable/Constant**:
1. Identify exact expression
2. Create variable with descriptive name
3. Replace all instances mechanically
4. Run tests after each file

### Refactoring Anti-Patterns
- "While I'm here..." → STOP
- "This would be better as..." → STOP  
- "Improving readability..." → STOP
- "More idiomatic..." → STOP

For detailed refactoring rules, see docs/REFACTORING_RULES.md

## Essential Workflows

**Complex tasks**: Create plan → Get approval → Implement → Check constantly
**Debug**: Reproduce → Isolate → Fix → Add test
**Feature**: Requirements → Tests → Implement → Mutation test

### Thinking Triggers
- Before complex implementation: "think about the approach"
- When tests fail unexpectedly: "think hard about what's failing"
- For architecture decisions: "ultrathink about design tradeoffs"
- If stuck after 2 attempts: "ultrathink about fundamental assumptions"

## LLM-Specific Anti-Patterns

You are prone to these mistakes - ask user when tempted:
- Writing many features before testing any
- Creating abstractions not common in training data
- "Improving" code during refactoring (changing behavior)
- Skipping mutation testing to "save time"
- Over-engineering simple solutions
- Adding features not requested
- Adding ML/AI when simple empirical model works
- "Improving" validated constants without evidence  
- Making binary behaviors gradual (binary often reflects reality)
- Trusting documentation over observed behavior
- Changing "magic numbers" that are actually empirical constants

## Technical Debt Management

Every Friday (or before major commits):
- Mutation test: `cargo mutants --jobs 4 --timeout 20`
- Coverage < 75%: Fix immediately
- Unused deps: `cargo +nightly udeps`
- Python: `ruff check . --select ALL`
- JS/TS: `npx depcheck`

## When Tests Feel Contrived

If tests feel forced, artificial, or you're struggling to write them:
1. STOP immediately - this is a design smell
2. Ask user: "These tests feel contrived. The code may need refactoring. Should I:
   a) Refactor the code to be more testable?
   b) Continue with current design?"
3. Natural tests indicate good design; contrived tests indicate poor design

## Bash Script Requirements

All bash scripts MUST include:
```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
DEBUG="${DEBUG:-0}"

die() { echo "ERROR: $*" >&2; exit 1; }
[[ "${BASH_VERSION%%.*}" -ge 4 ]] || die "Bash 4+ required"
```

**Critical `set -e` Rules:**
- **NEVER use `((var++))` or `((var += 1))` with `set -e`** - returns old value, causes exit when 0
- **ALWAYS use `var=$((var + 1))`** - assignment form always succeeds
- **SUBPROCESS CALLS**: Use `|| true` for commands that might fail: `python script.py || true`
- **COMMAND SUBSTITUTION**: Handle failures: `result=$(command 2>&1 || true)`
- **CONDITIONAL TESTS**: Use explicit success: `if command >/dev/null 2>&1; then`
- **GENERAL RULE**: Any command returning non-zero terminates script - plan for failure modes

Requirements:
- Lint: `shellcheck -x *.sh scripts/**/*.sh`
- Test: `bats-core` for all scripts
- Self-test mode with `--test` flag

## Pedantic Languages as Force Multipliers

Rust and TypeScript help you through compiler feedback:
- Read full error messages carefully
- Don't fight the type system - it's helping
- Use compiler suggestions
- Leverage ownership system (Rust) for correctness

## Repository Standards

- Install executables to `~/.local/bin/`
- Use SQLite for persistent data in `~/.local/share/<tool-name>/`
- Source control: Use `gh` CLI for GitHub operations
- Commit format: `type(scope): description` where type ∈ {feat, fix, docs, style, refactor, test, chore}

### Pre-commit Checks
Before ANY commit, check for and run:
1. `mask pre-commit` if maskfile.md exists
2. `pre-commit run --all-files` if .pre-commit-config.yaml exists
3. `npm run pre-commit` if defined in package.json
4. At minimum: format + lint + test

NEVER use `--no-verify` to skip checks.

## Tool-Specific Disciplines

### Python
- Use `uv` exclusively (not pip, poetry)
- Format: `black . --check` → `black .`
- Lint: `ruff check .` → `ruff check . --fix`
- Test: `pytest -xvs` (stop on first failure)
- Error handling: Return `Optional[T]` or `Union[T, Error]`

### Rust
- Format: `cargo fmt -- --check` → `cargo fmt`
- Lint: `cargo clippy -- -D warnings`
- Test: `cargo test && cargo mutants`
- Use workspace for multiple tools
- Prefer `Result<T, E>` over panics

### TypeScript
- Format: `npx prettier --check .` → `npx prettier --write .`
- Lint: `npx eslint . --ext .ts,.tsx,.js,.jsx`
- Type check: `npx tsc --noEmit`
- Choose runtime based on needs (Bun/Node+pnpm/Deno)
- Avoid for system tools

## References

- Language details: `docs/LANGUAGE_SELECTION_GUIDE.md`
- Bash development: `docs/BASH_DEVELOPMENT_GUIDE.md`
- Python standards: `docs/PYTHON_DEVELOPMENT_GUIDE.md`
- Build tools: `docs/BUILD_TOOLS_GUIDE.md`
- Installation: `docs/INSTALLATION_AND_STRUCTURE.md`
- Parent standards: `~/.claude/CLAUDE.md` and project-specific CLAUDE.md files