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