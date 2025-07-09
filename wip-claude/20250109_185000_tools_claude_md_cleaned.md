# CLAUDE.md - Development Philosophy & Complex Patterns

This file provides behavioral guidance and philosophy for development projects. Basic formatting, Python version requirements, and mechanical validations are handled by dot_claude/CLAUDE.md and claude-hooks.

## 🚨 Language Selection Philosophy

### The Bash-First Principle
1. Can the task be done with standard Unix tools? → **Use bash**
2. Does it need specific language libraries? → Use that language
3. Does it need to be distributed as a binary? → Use Rust
4. Is it a one-off data analysis? → Consider Python with uvx
5. **Default: Start with bash, refactor if needed**

### Language Escalation Patterns
- Bash struggles with performance → Add Rust helpers (keep bash orchestration)
- Need complex data structures → Move to Python or Rust
- Complexity creep is technical debt → Resist moving to "fancier" language

## Development Operational Modes

Beyond Claude's built-in Planning/Research modes:

### Implementation Mode
**Triggers**: "implement", "fix", "create", "write" (with approved plan)
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
- Follow refactoring processes exactly
- ZERO behavior changes allowed
- Tests must stay green
**Exit**: Refactoring complete with unchanged behavior

## Core Development Philosophy

### Code Quality Principles
- Prefer simple, maintainable solutions over clever ones
- Make smallest reasonable changes
- Match existing code style within files
- Ask permission before reimplementing from scratch

### Documentation Philosophy
- Never remove comments unless provably false
- Start files with 2-line ABOUTME comment (when creating new files)
- Keep comments evergreen (describe current state)
- README.md: Always put commands/usage at top under "## Quick Start"

### Change Discipline
- Never make unrelated changes to current task
- Never use --no-verify when committing
- Never name things as 'improved', 'new', 'enhanced'
- Check conversation history to prevent regressions

## Empirical Development Principle

When empirical data contradicts theory, data wins:
- Test actual behavior, don't trust documentation
- Validate with real-world data before claiming improvements
- Use regression tests as source of truth

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

## Testing Philosophy - The OCR 0% Lesson

**Critical Case Study**: OCR module had property tests, snapshot tests, integration tests, fuzz tests. Mutation testing revealed **0% effectiveness** - none verified correctness.

### Mutation Testing Discipline

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

### When Tests Feel Contrived
If tests feel forced, artificial, or you're struggling to write them:
1. STOP immediately - this is a design smell
2. Ask user: "These tests feel contrived. The code may need refactoring. Should I:
   a) Refactor the code to be more testable?
   b) Continue with current design?"
3. Natural tests indicate good design; contrived tests indicate poor design

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

## Plan Execution Discipline

During Implementation Mode:
- Reference plan constantly
- After each function/file: check alignment with plan
- On deviation: "Plan says X, found Y. Should I proceed with X or adjust?"
- Complete ALL plan items before considering done
- No "while I'm here" additions

## Bash Development Patterns

### Understanding `set -e` Gotchas
While hooks enforce headers, understanding WHY is critical:

**Critical `set -e` Rules:**
- **NEVER use `((var++))` or `((var += 1))` with `set -e`** - returns old value, causes exit when 0
- **ALWAYS use `var=$((var + 1))`** - assignment form always succeeds
- **SUBPROCESS CALLS**: Use `|| true` for commands that might fail
- **COMMAND SUBSTITUTION**: Handle failures: `result=$(command 2>&1 || true)`
- **GENERAL RULE**: Any command returning non-zero terminates script

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

## Repository Standards

- Install executables to `~/.local/bin/`
- Use SQLite for persistent data in `~/.local/share/<tool-name>/`
- Source control: Use `gh` CLI for GitHub operations
- Commit format: `type(scope): description` where type ∈ {feat, fix, docs, style, refactor, test, chore}

## Pedantic Languages as Force Multipliers

Rust and TypeScript help through compiler feedback:
- Read full error messages carefully
- Don't fight the type system - it's helping
- Use compiler suggestions
- Leverage ownership system (Rust) for correctness

## Essential Workflows

**Complex tasks**: Create plan → Get approval → Implement → Check constantly
**Debug**: Reproduce → Isolate → Fix → Add test
**Feature**: Requirements → Tests → Implement → Mutation test

### Thinking Triggers
- Before complex implementation: "think about the approach"
- When tests fail unexpectedly: "think hard about what's failing"
- For architecture decisions: "ultrathink about design tradeoffs"
- If stuck after 2 attempts: "ultrathink about fundamental assumptions"

## References

- Parent standards: `~/.claude/CLAUDE.md` (global config)
- Automated enforcement: `tools/claude-hooks/`
- Language details: `docs/LANGUAGE_SELECTION_GUIDE.md`
- Refactoring rules: `docs/REFACTORING_RULES.md`