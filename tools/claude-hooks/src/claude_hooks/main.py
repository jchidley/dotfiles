#!/usr/bin/env python3
"""Main entry point for Claude Code hooks."""

import json
import logging
import os
import sys
from pathlib import Path

from .formatters import format_file
from .validators import validate_file

# Set up logging
log_level = logging.DEBUG if os.getenv("DEBUG") == "1" else logging.WARNING
logging.basicConfig(
    level=log_level,
    format="%(levelname)s: %(message)s" if log_level == logging.WARNING else "DEBUG: %(message)s",
)
logger = logging.getLogger(__name__)


def main():
    """Main entry point for Claude Code hook."""
    try:
        # Read JSON from stdin
        json_input = json.loads(sys.stdin.read())
        logger.debug(f"Received JSON: {json_input}")

        # Extract file path
        file_path = json_input.get("params", {}).get("file_path")
        if not file_path:
            logger.error("No file path provided")
            sys.exit(1)

        file_path = Path(file_path)
        if not file_path.exists():
            logger.error(f"File does not exist: {file_path}")
            sys.exit(1)

        logger.debug(f"Processing file: {file_path}")
        logger.debug(f"File extension: {file_path.suffix}")

        # Change to file's directory for relative operations
        original_dir = Path.cwd()
        os.chdir(file_path.parent)

        try:
            # Run formatting (non-blocking)
            format_file(file_path)

            # Run validation (may block)
            errors = validate_file(file_path)

            if errors:
                for error in errors:
                    print(error, file=sys.stderr)
                sys.exit(1)

            logger.debug("Hook processing completed successfully")

        finally:
            # Restore original directory
            os.chdir(original_dir)

    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse JSON input: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Hook failed: {e}")
        if logger.isEnabledFor(logging.DEBUG):
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()