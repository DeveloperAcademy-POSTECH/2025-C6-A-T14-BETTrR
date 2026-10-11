#!/usr/bin/env python3
"""Restore GoogleService-Info.plist from a base64 GitHub secret."""

from __future__ import annotations

import argparse
import base64
import binascii
import os
import plistlib
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--secret-env", default="GOOGLE_SERVICE_INFO_PLIST_BASE64")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    encoded = os.environ.get(args.secret_env, "")
    if not encoded:
        raise SystemExit(f"missing required environment variable: {args.secret_env}")

    normalized = "".join(encoded.split())
    try:
        decoded = base64.b64decode(normalized, validate=True)
    except binascii.Error as error:
        raise SystemExit("invalid base64 GoogleService-Info.plist secret") from error

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    try:
        values = plistlib.loads(decoded)
        if not isinstance(values, dict):
            raise ValueError("not a dictionary")
    except Exception:
        raise SystemExit("invalid GoogleService-Info.plist secret") from None
    # Never truncate an existing local configuration; permissions are private from creation.
    descriptor = os.open(output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(decoded)
    except BaseException:
        output.unlink(missing_ok=True)
        raise
    print(f"restored {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
