#!/usr/bin/env python3
"""Validate xcresult summary counts and emit a sanitized contract summary."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


REQUIRED_INT_FIELDS = (
    "totalTestCount",
    "passedTests",
    "failedTests",
    "skippedTests",
    "expectedFailures",
)


def validated_summary(summary: Any, expected_passed: int, expected_skipped: int) -> dict[str, int | str]:
    if not isinstance(summary, dict):
        raise ValueError("GeminiContract summary must be a JSON object")

    if summary.get("result") != "Passed":
        raise ValueError("GeminiContract result must be Passed")

    values: dict[str, int] = {}
    for field in REQUIRED_INT_FIELDS:
        value = summary.get(field)
        if type(value) is not int or value < 0:
            raise ValueError(f"GeminiContract summary field {field} must be a nonnegative integer")
        values[field] = value

    if values["totalTestCount"] != expected_passed:
        raise ValueError("GeminiContract total test count mismatch")
    if values["passedTests"] != expected_passed:
        raise ValueError("GeminiContract passed test count mismatch")
    if values["failedTests"] != 0:
        raise ValueError("GeminiContract failed tests are present")
    if values["skippedTests"] != expected_skipped:
        raise ValueError("GeminiContract skipped test count mismatch")
    if values["expectedFailures"] != 0:
        raise ValueError("GeminiContract expected failures are present")

    return {
        "result": "Passed",
        "totalTestCount": values["totalTestCount"],
        "passedTests": values["passedTests"],
        "failedTests": values["failedTests"],
        "skippedTests": values["skippedTests"],
        "expectedFailures": values["expectedFailures"],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("summary_json", type=Path)
    parser.add_argument("--expected-passed", type=int, required=True)
    parser.add_argument("--expected-skipped", type=int, default=0)
    parser.add_argument("--write-sanitized", type=Path)
    args = parser.parse_args()

    try:
        summary = json.loads(args.summary_json.read_text(encoding="utf-8"))
        sanitized = validated_summary(summary, args.expected_passed, args.expected_skipped)
    except (ValueError, OSError) as error:
        raise SystemExit(str(error)) from error

    print(
        "GeminiContract sanitized summary: "
        f"result={sanitized['result']} "
        f"total={sanitized['totalTestCount']} "
        f"passed={sanitized['passedTests']} "
        f"skipped={sanitized['skippedTests']} "
        f"failed={sanitized['failedTests']} "
        f"expectedFailures={sanitized['expectedFailures']}"
    )

    if args.write_sanitized:
        args.write_sanitized.write_text(json.dumps(sanitized, sort_keys=True) + "\n", encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
