Execute comprehensive security review:

1. **Project Analysis**
   - Identify project type using glob for common files (package.json, requirements.txt, go.mod, etc.)
   - List primary language and frameworks
   - Note authentication/authorization libraries in use

2. **Secrets and Credentials Scan**
   Use grep to search for:
   - Patterns: "password.*=", "api_key", "secret", "token", "private_key"
   - AWS patterns: "AKIA[0-9A-Z]{16}"
   - Generic API keys: "[a-zA-Z0-9]{32,}"
   - Connection strings with embedded credentials
   - Check .env, config files, and source code

3. **Dependency Vulnerability Check**
   - For Node.js: Check package.json and package-lock.json
   - For Python: Check requirements.txt or pyproject.toml
   - For Go: Check go.mod
   - Note any outdated major versions
   - Flag known vulnerable package versions

4. **Code Pattern Analysis**
   Use grep to find risky patterns:
   - SQL queries: "SELECT.*FROM.*WHERE", "INSERT INTO", check for string concatenation
   - Command execution: "exec(", "system(", "eval(", "subprocess", "os.system"
   - File operations: "open(", "readFile", "writeFile" without validation
   - Unsafe deserialization: "pickle.loads", "yaml.load", "JSON.parse" with user input
   - CORS: "*" in Access-Control-Allow-Origin

5. **Authentication/Authorization Review**
   Search for and examine:
   - Login/auth endpoints
   - Session management code
   - JWT implementation
   - Password hashing (look for bcrypt, argon2, or weak MD5/SHA1)
   - Authorization checks before sensitive operations

6. **Input Validation Audit**
   - Find all user input points (forms, APIs, file uploads)
   - Check for validation before database queries
   - Verify file upload restrictions
   - Look for regex validation patterns
   - Check Content-Type validation

7. **Configuration Security**
   Examine configuration files for:
   - Debug mode enabled in production
   - Weak cryptographic settings
   - Permissive CORS policies
   - Missing security headers
   - Default admin credentials

8. **Generate Report**
   Create SECURITY_REVIEW_[timestamp].md with:
   - Project type and technology stack
   - Total files scanned and patterns checked
   - Summary of findings by category
   - Detailed findings organized by severity:
     * Critical: RCE, SQLi, hardcoded secrets, auth bypass
     * High: XSS, insecure deserialization, weak crypto
     * Medium: Missing validation, verbose errors, outdated deps
     * Low: Best practices, code quality, minor config issues
   - Specific remediation steps for each finding
   - Code examples showing vulnerable vs secure patterns
   - Prioritized action plan

Output: "Security review complete. Found X critical, Y high, Z medium issues. Report saved to SECURITY_REVIEW_[timestamp].md"
