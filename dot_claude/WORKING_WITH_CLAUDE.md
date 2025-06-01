# Working with Claude - Human Side of the Symbiosis

## Before Starting Work
When you notice we're about to work on something we've done before, say:
- "Check git log for previous [topic] work"
- "Search sessions for when we last did [X]"
- "What failed approaches are documented for [Y]?"

## During Work
Help me help you by:
- **Correcting me immediately** when I repeat a mistake
- **Adding failed approaches** to HANDOFF.md right when they fail
- **Saying "we tried that already"** - I'll search for context

## Pattern Recognition
You're better at recognizing when we're in familiar territory. Say things like:
- "This feels like the bash script issue from last week"
- "We had a similar problem with chezmoi templates"
- "Check if this is the same as [previous issue]"

## What Works Best

### You Excel At:
- Recognizing patterns across sessions
- Knowing when something "feels wrong"
- Remembering the "why" behind decisions
- Spotting when I'm about to repeat mistakes

### I Excel At:
- Searching through large codebases
- Finding specific error messages in history
- Following systematic procedures
- Maintaining consistent state in files

## Magic Phrases
These prompts help me use our history effectively:
- "What does git blame say about this line?"
- "Find our previous work on [specific feature]"
- "Check PROJECT_WISDOM for [topic]"
- "Search for [error message] in sessions/"

## PROJECT_WISDOM.md - Our Shared Memory
This file captures hard-won insights that both of us should reference:
- **For You**: When I mention a technology/tool, remind me to check PROJECT_WISDOM first
- **For Me**: I'll proactively search it when starting work on familiar topics
- **Format**: Titles must be searchable (e.g., "Docker Build - Layer Cache Issues")
- **Growth**: Add insights during /checkpoint when we discover something important

## Remember
Our system works best when you guide my powerful but amnesiac brain with your pattern-matching intuition.