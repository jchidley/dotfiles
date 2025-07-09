#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
DEBUG="${DEBUG:-1}"

die() { echo "ERROR: $*" >&2; exit 1; }
[[ "${BASH_VERSION%%.*}" -ge 4 ]] || die "Bash 4+ required"

# ABOUTME: Test the Python claude-hooks implementation
# Creates test files and runs the hooks to verify functionality

cd "$(dirname "${BASH_SOURCE[0]}")" || die "Failed to cd to script directory"

echo "=== Testing Claude Hooks (Python Implementation) ==="

# Test 1: Python file
echo "=== Test 1: Python file ==="
cat > /tmp/test_hooks.py <<'EOF'
def hello():
    print("Hello world")
    
if __name__ == "__main__":
    hello()
EOF

echo '{"params": {"file_path": "/tmp/test_hooks.py"}}' | DEBUG=1 uvx --from . claude-hooks
echo ""

# Test 2: Bash file with proper header
echo "=== Test 2: Bash file with proper header ==="
cat > /tmp/test_good.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
DEBUG="${DEBUG:-0}"

die() { echo "ERROR: $*" >&2; exit 1; }
[[ "${BASH_VERSION%%.*}" -ge 4 ]] || die "Bash 4+ required"

echo "Hello world"
EOF

echo '{"params": {"file_path": "/tmp/test_good.sh"}}' | DEBUG=1 uvx --from . claude-hooks
echo ""

# Test 3: Bash file missing header (should fail)
echo "=== Test 3: Bash file missing header (should fail) ==="
cat > /tmp/test_bad.sh <<'EOF'
#!/usr/bin/env bash
echo "Missing safety features"
EOF

echo '{"params": {"file_path": "/tmp/test_bad.sh"}}' | DEBUG=1 uvx --from . claude-hooks || echo "Expected failure caught"
echo ""

# Test 4: Bash file with dangerous pattern (should warn)
echo "=== Test 4: Bash file with dangerous pattern (should warn) ==="
cat > /tmp/test_dangerous.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
DEBUG="${DEBUG:-0}"

die() { echo "ERROR: $*" >&2; exit 1; }
[[ "${BASH_VERSION%%.*}" -ge 4 ]] || die "Bash 4+ required"

counter=0
((counter++))  # This is dangerous with set -e
EOF

echo '{"params": {"file_path": "/tmp/test_dangerous.sh"}}' | DEBUG=1 uvx --from . claude-hooks
echo ""

# Cleanup
rm -f /tmp/test_hooks.py /tmp/test_good.sh /tmp/test_bad.sh /tmp/test_dangerous.sh

echo "=== All tests completed ==="