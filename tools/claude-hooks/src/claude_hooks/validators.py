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
    file_name = file_path.name
    
    if ext == ".sh":
        # Bash validation is critical - these are blocking errors
        errors.extend(validate_bash_script(file_path))
    
    # Check if this is a test file
    if (ext in [".py", ".ts", ".js"] and 
        (file_name.startswith("test_") or file_name.endswith("_test.py") or 
         file_name.endswith(".test.ts") or file_name.endswith(".test.js"))):
        # Test quality validation - non-blocking warnings
        validate_test_quality(file_path)
    
    # Phase 3: Documentation patterns validation (non-blocking)
    validate_documentation_patterns(file_path)
    
    # Phase 3: Repository standards validation (non-blocking)
    validate_repository_standards(file_path)
    
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
            ["shellcheck", "-x", str(file_path)],
            capture_output=True,
            text=True,
            cwd=file_path.parent,
        )
        if result.returncode != 0:
            errors.append(f"ERROR: shellcheck found issues in {file_name}")
            # Show first 20 lines of shellcheck output
            output_lines = result.stdout.splitlines()[:20]
            for line in output_lines:
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
        ifs_found = False
        debug_found = False
        test_flag_found = False
        
        # Check first 10 lines for set -euo pipefail
        for line in lines[:10]:
            if "set -euo pipefail" in line:
                header_found = True
                break
                
        if not header_found:
            errors.append("Bash script missing required 'set -euo pipefail' in header")
            
        # Check first 20 lines for die() function and other patterns
        for line in lines[:20]:
            if "die()" in line:
                die_found = True
            if "BASH_VERSION" in line:
                bash_check_found = True
            if "IFS=$'\\n\\t'" in line:
                ifs_found = True
            if re.search(r'DEBUG="\$\{DEBUG:-0\}"', line):
                debug_found = True
                
        if not die_found:
            errors.append("Bash script missing required die() function")
            
        if not bash_check_found:
            print("WARNING: Bash script missing Bash 4+ version check", file=sys.stderr)
            
        # Phase 2: Additional bash completeness checks
        if not ifs_found:
            print("WARNING: Consider setting IFS=$'\\n\\t' for safer word splitting", file=sys.stderr)
            
        if not debug_found:
            print("WARNING: Consider adding DEBUG=\"${DEBUG:-0}\" pattern for debug support", file=sys.stderr)
        
        # Check for --test flag implementation
        for line in lines:
            if "--test" in line or "-t" in line and "test mode" in content.lower():
                test_flag_found = True
                break
                
        if len(lines) > 50 and not test_flag_found:  # Only warn for non-trivial scripts
            print("WARNING: Consider implementing --test flag for dry-run capability", file=sys.stderr)
            
        # Check for test file existence
        test_patterns = [
            file_path.with_suffix(".bats"),
            file_path.parent / "tests" / f"{file_path.stem}.bats",
            file_path.parent / "test" / f"{file_path.stem}.bats",
        ]
        
        has_tests = any(test_file.exists() for test_file in test_patterns)
        if not has_tests and len(lines) > 50:
            print("WARNING: No bats-core test file found. Consider adding tests.", file=sys.stderr)
            
        # Check for dangerous patterns
        if re.search(r'\(\(.*\+\+\)\)|\(\(.*\+=.*\)\)', content):
            print("WARNING: Dangerous arithmetic pattern detected (((var++)) or ((var+=1)))", file=sys.stderr)
            print("Use var=$((var + 1)) instead to avoid issues with set -e", file=sys.stderr)
            
    except Exception as e:
        logger.error(f"Failed to read bash script: {e}")
        errors.append(f"Failed to validate bash script: {e}")
        
    return errors


def validate_test_quality(file_path: Path) -> None:
    """Validate test file quality (non-blocking warnings)."""
    try:
        content = file_path.read_text()
        file_name = file_path.name
        
        # Check for ineffective test patterns (the "OCR 0% problem")
        ineffective_patterns = [
            # Structure-only checks
            (r'assert\s+\w+\.is_valid(?:\s|$)', "Structure-only assertion: assert X.is_valid"),
            (r'assert\s+\w+\s+is\s+not\s+None(?:\s|$)', "Null-check only: assert X is not None"),
            (r'assert\s+\w+\s*!=\s*None(?:\s|$)', "Null-check only: assert X != None"),
            (r'expect\(\w+\)\.toBeDefined\(\)', "Structure-only: expect(X).toBeDefined()"),
            (r'expect\(\w+\)\.not\.toBeNull\(\)', "Null-check only: expect(X).not.toBeNull()"),
            (r'expect\(\w+\)\.toBeTruthy\(\)', "Truthy-check only: expect(X).toBeTruthy()"),
            # Property existence without value checks
            (r'assert\s+hasattr\(\w+,\s*[\'\"]\w+[\'\"]', "Property existence only: assert hasattr(X, 'prop')"),
            (r'expect\(\w+\)\.toHaveProperty\([\'\"]\w+[\'\"]\)', "Property existence only: expect(X).toHaveProperty()"),
        ]
        
        warnings_found = []
        for pattern, message in ineffective_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                warnings_found.append(message)
        
        # Check for missing concrete value assertions
        has_value_assertions = False
        value_patterns = [
            r'assert\s+\w+\s*==\s*["\'\d]',  # assert x == "value" or assert x == 123
            r'assert\s+\w+\s*>=?\s*\d',      # assert x > 5
            r'expect\(\w+\)\.toBe\(["\'\d]', # expect(x).toBe("value")
            r'expect\(\w+\)\.toEqual\(',     # expect(x).toEqual(...)
            r'self\.assertEqual\(',           # self.assertEqual(...)
            r'pytest\.approx\(',              # pytest.approx(...)
        ]
        
        for pattern in value_patterns:
            if re.search(pattern, content):
                has_value_assertions = True
                break
        
        # Print warnings
        if warnings_found:
            print(f"\n⚠️  Test Quality Warning in {file_name}:", file=sys.stderr)
            print("These patterns often indicate ineffective tests (OCR 0% problem):", file=sys.stderr)
            for warning in warnings_found:
                print(f"  - {warning}", file=sys.stderr)
            print("\nConsider adding concrete value assertions that verify actual behavior.", file=sys.stderr)
            print("Tests should catch logic/calculation errors, not just structure.", file=sys.stderr)
        
        if not has_value_assertions and len(content) > 100:  # Skip warning for very small test files
            print(f"\n⚠️  Test Quality Warning in {file_name}:", file=sys.stderr)
            print("No concrete value assertions found. Tests should verify actual values, not just structure.", file=sys.stderr)
            print("Example: assert result.score == 0.95 (not just assert result.score is not None)", file=sys.stderr)
            
    except Exception as e:
        logger.error(f"Failed to validate test quality: {e}")


def validate_documentation_patterns(file_path: Path) -> None:
    """Validate documentation patterns (non-blocking warnings)."""
    try:
        content = file_path.read_text()
        file_name = file_path.name
        ext = file_path.suffix.lower()
        lines = content.splitlines()
        
        # Check ABOUTME comment for code files
        if ext in [".py", ".sh", ".rs", ".ts", ".js"] and len(lines) >= 2:
            # Skip shebang line if present
            start_line = 1 if lines[0].startswith("#!") else 0
            
            # Check for ABOUTME pattern in first few lines
            has_aboutme = False
            for i in range(start_line, min(start_line + 5, len(lines))):
                if "ABOUTME" in lines[i] or "About:" in lines[i] or "Description:" in lines[i]:
                    has_aboutme = True
                    break
            
            if not has_aboutme and len(content) > 200:  # Only warn for non-trivial files
                print(f"\n⚠️  Documentation Warning in {file_name}:", file=sys.stderr)
                print("Missing 2-line ABOUTME comment at start of file.", file=sys.stderr)
                print("Example: # ABOUTME: This module handles user authentication", file=sys.stderr)
        
        # Check README.md structure
        if file_name == "README.md":
            # Look for Quick Start or Usage section near the top
            has_quick_start = False
            for i, line in enumerate(lines[:30]):  # Check first 30 lines
                if re.search(r'^#+\s*(Quick Start|Usage|Getting Started|Commands)', line, re.IGNORECASE):
                    has_quick_start = True
                    break
            
            if not has_quick_start:
                print(f"\n⚠️  README Structure Warning:", file=sys.stderr)
                print("README.md should have a 'Quick Start' or 'Usage' section near the top.", file=sys.stderr)
                print("Users want to know how to use your tool immediately.", file=sys.stderr)
                
    except Exception as e:
        logger.error(f"Failed to validate documentation patterns: {e}")


def validate_repository_standards(file_path: Path) -> None:
    """Validate repository standards (non-blocking warnings)."""
    try:
        content = file_path.read_text()
        file_name = file_path.name
        
        # Check for executable installation paths
        if re.search(r'install.*\s+(/usr/local/bin|/usr/bin|/bin)', content):
            print(f"\n⚠️  Repository Standard Warning in {file_name}:", file=sys.stderr)
            print("Executables should be installed to ~/.local/bin/ not system directories.", file=sys.stderr)
            print("This ensures user-level installation without requiring sudo.", file=sys.stderr)
        
        # Check for data storage patterns
        data_patterns = [
            (r'(/var/lib/|/etc/|/opt/)', "System directories"),
            (r'\./(data|db|database|storage)/', "Relative paths"),
        ]
        
        for pattern, location in data_patterns:
            if re.search(pattern, content) and "local/share" not in content:
                print(f"\n⚠️  Data Storage Warning in {file_name}:", file=sys.stderr)
                print(f"Found {location} for data storage. Use ~/.local/share/<tool-name>/ instead.", file=sys.stderr)
                print("This follows XDG base directory standards.", file=sys.stderr)
                break
                
    except Exception as e:
        logger.error(f"Failed to validate repository standards: {e}")


def validate_commit_message(message: str) -> list[str]:
    """Validate commit message format (returns errors)."""
    errors = []
    
    # Expected format: type(scope): description
    # Valid types: feat, fix, docs, style, refactor, test, chore
    valid_types = ["feat", "fix", "docs", "style", "refactor", "test", "chore"]
    
    # Basic pattern check
    pattern = r'^(' + '|'.join(valid_types) + r')(\([^)]+\))?: .+'
    if not re.match(pattern, message):
        errors.append(f"Commit message must follow format: type(scope): description")
        errors.append(f"Valid types: {', '.join(valid_types)}")
        errors.append(f"Example: feat(auth): add OAuth2 support")
    
    return errors