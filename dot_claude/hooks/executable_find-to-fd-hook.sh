#!/usr/bin/env bash
# find-to-fd-hook.sh - Intercept find commands and use fd instead
#
# This hook intercepts Bash commands and replaces 'find' with 'fd' where possible

set -euo pipefail

command="$1"

# Debug logging (uncomment to troubleshoot)
# echo "find-to-fd-hook: Intercepting command: $command" >&2

# Check if the command starts with 'find '
if [[ "$command" =~ ^find[[:space:]] ]]; then
    # Extract the find arguments
    find_args="${command#find }"
    
    # Try to convert common find patterns to fd
    # This is a simple conversion - fd has different syntax than find
    
    # Basic case: find . -name "pattern"
    if [[ "$find_args" =~ ^\.?[[:space:]]+-name[[:space:]]+"([^"]+)" ]]; then
        pattern="${BASH_REMATCH[1]}"
        echo "Using fd instead of find for pattern: $pattern" >&2
        fd "$pattern" 2>/dev/null && exit 1  # Block original command
    
    # Case: find /path -name "pattern"
    elif [[ "$find_args" =~ ^([^[:space:]]+)[[:space:]]+-name[[:space:]]+"([^"]+)" ]]; then
        path="${BASH_REMATCH[1]}"
        pattern="${BASH_REMATCH[2]}"
        echo "Using fd instead of find for pattern: $pattern in path: $path" >&2
        fd "$pattern" "$path" 2>/dev/null && exit 1  # Block original command
    
    # Case: find . -type f
    elif [[ "$find_args" =~ -type[[:space:]]+f ]]; then
        echo "Using fd instead of find for files" >&2
        fd --type f 2>/dev/null && exit 1  # Block original command
    
    # Case: find . -type d  
    elif [[ "$find_args" =~ -type[[:space:]]+d ]]; then
        echo "Using fd instead of find for directories" >&2
        fd --type d 2>/dev/null && exit 1  # Block original command
    fi
    
    # If we couldn't convert it, let find run normally
    echo "Complex find command, falling back to original find" >&2
fi

# Let the original command run
exit 0