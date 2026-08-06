"""Compatibility wrapper for the diagnose scaffold."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from diagnose import main  # noqa: E402


if __name__ == "__main__":
    main()