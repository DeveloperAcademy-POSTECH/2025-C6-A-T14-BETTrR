#!/usr/bin/env python3
"""Emit only fixed failure categories; never copy captured provider text."""
import argparse
import re
from pathlib import Path

CATEGORIES = (
    "configuration", "authentication", "quota", "serviceUnavailable",
    "deadline", "responseContract", "cancelled", "unknown",
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("log", type=Path)
    args = parser.parse_args()
    captured = args.log.read_text(encoding="utf-8", errors="replace")
    found = [category for category in CATEGORIES if re.search(
        r"GeminiContract failure: " + category + r"\b", captured
    )]
    for category in found or ["unknown"]:
        print(f"GeminiContract failure: {category}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
