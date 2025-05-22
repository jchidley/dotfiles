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