#!/usr/bin/env python3
"""Decide whether a change set should run Gemini contract tests."""

from __future__ import annotations

import argparse
import fnmatch
import sys


RUN_PATTERNS = (
    ".github/workflows/ios-gemini-contract.yml",
    "Bettr/Bettr/Application/FirebaseBootstrap.swift",
    "Bettr/Bettr/BettrApp.swift",
    "Bettr/Bettr/Domain/Services/AnalysisRateLimiting.swift",
    "Bettr/Bettr/Domain/Services/WordExtractionService.swift",
    "Bettr/Bettr/Presentation/Features/ScriptConfirm/ScriptGeminiCall.swift",
    "Bettr/Bettr/Presentation/Services/Gemini/LocalRateLimiter.swift",
    "Bettr/Bettr/Presentation/Services/Gemini/DeviceUUIDProvider.swift",
    "Bettr/BettrAI/**",
    "Bettr/Bettr.xcodeproj/project.pbxproj",
    "Bettr/Bettr.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
    "Bettr/Bettr.xcodeproj/xcshareddata/xcschemes/Bettr.xcscheme",
    "Bettr/BettrTests/GeminiContract/**",
    "Bettr/BettrTests/Unit/GeminiContractSupport.swift",
    "Bettr/BettrTests/Unit/GeminiContractSupportTests.swift",
    "Bettr/BettrTests/Unit/ScriptGeminiCallTests.swift",
    "Bettr/TestPlans/Default.xctestplan",
    "Bettr/TestPlans/GeminiContract.xctestplan",
    "scripts/gemini-contract/**",
    "scripts/tests/gemini-contract-*.sh",
)


def normalized_paths(lines: list[str]) -> list[str]:
    paths: list[str] = []
    for line in lines:
        path = line.strip()
        if path.startswith("./"):
            path = path[2:]
        if path:
            paths.append(path)
    return paths


def is_impacting(path: str) -> bool:
    return any(fnmatch.fnmatchcase(path, pattern) for pattern in RUN_PATTERNS)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="*", help="Changed paths to evaluate.")
    parser.add_argument(
        "--from-stdin",
        action="store_true",
        help="Read newline-delimited changed paths from stdin.",
    )
    args = parser.parse_args()

    raw_paths = args.paths
    if args.from_stdin:
        raw_paths.extend(sys.stdin.read().splitlines())

    paths = normalized_paths(raw_paths)
    matched = [path for path in paths if is_impacting(path)]

    if matched:
        print("run=true")
        for path in matched:
            print(path)
        return 0

    print("run=false")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
