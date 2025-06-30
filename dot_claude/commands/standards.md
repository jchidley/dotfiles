Check project compliance with CLAUDE.md standards and create a plan to fix any issues.

1. Read all relevant CLAUDE.md files:
   - ~/.claude/CLAUDE.md (global configuration)
   - ./CLAUDE.md (project-specific if exists)
   - /home/jack/tools/CLAUDE.md (development standards)

2. Analyze current project for compliance:
   - Check for required documentation (PROJECT_WISDOM.md, HANDOFF.md)
   - Verify wip-claude/ folder usage for temporary docs
   - Check Python code for uv usage, testing, and typing
   - Verify shell scripts follow safety standards
   - Check Git workflow compliance
   - Review error handling patterns

3. Create a comprehensive report showing:
   - ✅ Standards that are properly followed
   - ❌ Standards that are violated or missing
   - ⚠️  Areas that need improvement

4. If any violations found:
   - Use built-in planning mode to create implementation plan
   - Prioritize critical issues (security, safety)
   - Include specific file paths and changes needed

5. Focus areas based on project type:
   - Python projects: uv, ruff, pytest, mypy
   - Shell scripts: shellcheck, set -euo pipefail
   - Documentation: proper structure and naming
   - Git: conventional commits, branch protection