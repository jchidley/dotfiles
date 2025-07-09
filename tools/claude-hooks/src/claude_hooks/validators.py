"""Validation checks for files."""

import logging
import re
import shutil
import subprocess
import sys
from pathlib import Path

logger = logging.getLogger(__name__)


def validate_file(file_path: Path) -> list[str]:
    """Validate file and return list of blocking errors."""
    errors = []
    ext = file_path.suffix.lower()
    
    if ext == ".sh":
        # Bash validation is critical - these are blocking errors
        errors.extend(validate_bash_script(file_path))
    
    # Non-blocking warnings are printed directly to stderr
    # This matches the original bash behavior
    return errors


def validate_bash_script(file_path: Path) -> list[str]:
    """Validate bash script requirements."""
    errors = []
    file_name = file_path.name
    
    # Run shellcheck if available
    if shutil.which("shellcheck"):
        result = subprocess.run(
            ["shellcheck", "-x", file_name],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            errors.append(f"ERROR: shellcheck found issues in {file_name}")
            # Show first 20 lines of shellcheck output
            lines = result.stdout.splitlines()[:20]
            for line in lines:
                print(line, file=sys.stderr)
            return errors  # Return immediately on shellcheck failure
    else:
        logger.debug("shellcheck not found, skipping bash linting")
    
    # Read file content for header validation
    try:
        content = file_path.read_text()
        lines = content.splitlines()
        
        # Check for required bash header elements
        header_found = False
        die_found = False
        bash_check_found = False
        
        # Check first 10 lines for set -euo pipefail
        for line in lines[:10]:
            if "set -euo pipefail" in line:
                header_found = True
                break
                
        if not header_found:
            errors.append("Bash script missing required 'set -euo pipefail' in header")
            
        # Check first 15 lines for die() function
        for line in lines[:15]:
            if "die()" in line:
                die_found = True
            if "BASH_VERSION" in line:
                bash_check_found = True
                
        if not die_found:
            errors.append("Bash script missing required die() function")
            
        if not bash_check_found:
            print("WARNING: Bash script missing Bash 4+ version check", file=sys.stderr)
            
        # Check for dangerous patterns
        if re.search(r'\(\(.*\+\+\)\)|\(\(.*\+=.*\)\)', content):
            print("WARNING: Dangerous arithmetic pattern detected (((var++)) or ((var+=1)))", file=sys.stderr)
            print("Use var=$((var + 1)) instead to avoid issues with set -e", file=sys.stderr)
            
    except Exception as e:
        logger.error(f"Failed to read bash script: {e}")
        errors.append(f"Failed to validate bash script: {e}")
        
    return errors