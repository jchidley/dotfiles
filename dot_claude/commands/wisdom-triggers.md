# Wisdom Capture Triggers

Universal patterns for identifying insights worthy of capture in PROJECT_WISDOM files.

## Technical Discoveries
- Tool usage: "Found that [tool] works better with [specific approach]"
- Error solutions: "Fixed [error message] by [specific solution]"
- Configuration: "[Setting/config] must be [requirement] because [reason]"
- Workflow improvements: "Using [approach] instead of [old way] saves time/prevents errors"
- Integration insights: "[Tool A] and [Tool B] interact in [unexpected way]"
- Performance findings: "[Action] is slow/fast because [technical reason]"

## Conversation Triggers
- Established practice: "we should always..."
- Pattern recognition: "we've done this before..." / "did we see this..." / "I think I've seen this..."
- Critical knowledge: "remember that..." / "let's not forget..." / "this is important..."
- Forward guidance: "next time..." / "in the future..."
- Lessons learned: "lesson learned..." / "gotcha..."

## Evolution Patterns
- Alternative approaches: "tried X, Y worked better" / "instead of..."
- Anti-patterns: "doesn't work" / "won't work" / "failed"
- Discovery corrections: "actually" / "turns out" / "realized"
- System invariants: "must" / "always" / "never" (especially with numbers/data)

## Example Prompting Format

When insights detected, present them clearly:

```
💡 Wisdom capture opportunities detected:

[✓] Pattern Recognition: "we've done this before with Docker..."
    → Suggested entry: Docker container memory limits pattern

[✓] System Invariant: "this must always be set to 8GB..."
    → Suggested entry: Memory allocation constraint (empirically validated)

[✓] Evolution Discovery: "we tried async first, but sync worked better..."
    → Suggested entry: Sync vs Async decision for [context]

Add these to CURRENT_PROJECT_WISDOM.md? (Y/n)
```

## Wisdom Entry Format

```markdown
### [Date]: [Topic/Technology - Specific Discovery]
**Insight**: [The realization with specific details/errors]
**Impact**: [How this changes future approach]
**Note**: [Context or example. Title should contain searchable keywords]
```