# CLAUDE.md Methodology and Documentation

## Credits & Inspiration

This configuration approach is inspired by:
- Manuel Odendahl's CLAUDE.md methodology for AI-assisted development
- Simon Willison's patterns for effective LLM interactions and prompt engineering

When updating CLAUDE.md files, consult their latest practices:
- https://github.com/wesen/claude-engineer-coding-guidelines
- https://simonwillison.net/tags/llms/

## Configuration Philosophy

The CLAUDE.md system uses a hierarchical approach:
1. **Global configuration** (`~/.claude/CLAUDE.md`) - Core behaviors that apply everywhere
2. **Project-specific** (`./CLAUDE.md`) - Repository or project-specific rules
3. **Local overrides** (`./CLAUDE.local.md`) - Personal, untracked customizations

## Session Management Architecture

Custom session management exists because built-in `--continue` and `--resume` have reliability issues. The workflow ensures persistent state across all sessions:

```
/start → work → /checkpoint → work → /wrap-session
  ↑                                         ↓
  └───────── Next Session ←──────────────┘
```

## Requirement Tracking Process

The requirement tracking system is designed for new PROJECT requirements that define how a software project should work. Regular Claude interactions (coding help, explanations, debugging) do not go through this process.

### Examples of PROJECT requirements vs regular tasks:
- PROJECT Requirement: "The API should validate all inputs" → REQ-0001
- PROJECT Requirement: "Users should be able to export data as CSV" → REQ-0002
- Regular Task: "Fix the typo in README.md" → Just do it, no requirement tracking
- Regular Task: "Explain how async/await works" → Just answer, no requirement tracking
- Regular Task: "Debug this error message" → Just help, no requirement tracking

### GitHub Integration Workflow:
1. Capture requirement locally in REQUIREMENTS.md (quick, offline-friendly)
2. When online, run `/req-to-issue REQ-XXXX` to create tracking issue
3. Track ALL implementation details in the GitHub issue (not separate files)
4. Use GitHub Projects to track implementation progress
5. Link PRs to requirement issues for full traceability

Implementation details, code examples, progress updates, and technical notes should all be documented directly in the GitHub issue comments and description.

## Interactive vs Autonomous Modes

### Interactive Mode (default)
- ASK for clarification when file paths or commands are ambiguous
- EXPLAIN your reasoning before making changes
- PROVIDE the exact sudo command for user to execute (never run sudo directly)
- VALIDATE assumptions by checking file existence before editing

### Autonomous Mode (Docker/CI environments)
- PROCEED with reasonable assumptions based on context
- ATTEMPT alternative solutions when initial approaches fail
- EXECUTE commands within container permissions