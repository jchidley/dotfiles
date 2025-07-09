"""Run formatting tools on files."""

import logging
import shutil
import subprocess
from pathlib import Path

logger = logging.getLogger(__name__)


def command_exists(command: str) -> bool:
    """Check if a command exists in PATH."""
    return shutil.which(command) is not None


def run_command(cmd: list[str], allow_failure: bool = True) -> bool:
    """Run a command and return True if successful."""
    logger.debug(f"Running: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
        )
        
        if result.returncode != 0 and not allow_failure:
            logger.error(f"Command failed: {' '.join(cmd)}")
            logger.error(f"stderr: {result.stderr}")
            return False
            
        return result.returncode == 0
        
    except Exception as e:
        logger.debug(f"Command failed: {' '.join(cmd)} - {e}")
        return False


def format_file(file_path: Path) -> None:
    """Format file based on extension."""
    ext = file_path.suffix.lower()
    file_name = file_path.name
    
    if ext == ".py":
        # Python: black formatting and ruff linting
        if command_exists("black"):
            run_command(["black", file_name])
        else:
            logger.debug("black not found, skipping Python formatting")
            
        if command_exists("ruff"):
            run_command(["ruff", "check", file_name, "--fix", "--quiet"])
        else:
            logger.debug("ruff not found, skipping Python linting")
            
    elif ext == ".rs":
        # Rust: cargo fmt
        if Path("Cargo.toml").exists() and command_exists("cargo"):
            run_command(["cargo", "fmt", "--", file_name])
        else:
            logger.debug("Not in a Rust project or cargo not found, skipping Rust formatting")
            
    elif ext in (".ts", ".tsx", ".js", ".jsx"):
        # TypeScript/JavaScript: prettier
        if command_exists("prettier"):
            run_command(["prettier", "--write", file_name])
        elif command_exists("npx"):
            run_command(["npx", "prettier", "--write", file_name])
        else:
            logger.debug("prettier not found, skipping JavaScript/TypeScript formatting")
            
    else:
        logger.debug(f"No specific formatter for .{ext} files")
        
    # Check for pre-commit hooks
    check_precommit_hooks(file_name)


def check_precommit_hooks(file_name: str) -> None:
    """Check and run pre-commit hooks if available."""
    # Check in current and parent directory
    for config_path in [Path("maskfile.md"), Path("../maskfile.md")]:
        if config_path.exists():
            logger.debug("Found maskfile.md - consider running 'mask pre-commit'")
            return
            
    for config_path in [Path(".pre-commit-config.yaml"), Path("../.pre-commit-config.yaml")]:
        if config_path.exists() and command_exists("pre-commit"):
            logger.debug("Running pre-commit hooks")
            run_command(["pre-commit", "run", "--files", file_name])
            return
            
    for config_path in [Path("package.json"), Path("../package.json")]:
        if config_path.exists():
            try:
                import json
                with open(config_path) as f:
                    package_data = json.load(f)
                    if "pre-commit" in package_data.get("scripts", {}):
                        logger.debug("Found pre-commit script in package.json - consider running 'npm run pre-commit'")
                        return
            except Exception:
                pass