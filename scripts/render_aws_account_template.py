#!/usr/bin/env python3
"""Render ${AWS_ACCOUNT_ID} in a manifest using the active AWS identity."""

import argparse
import os
import subprocess
from pathlib import Path


def account_id() -> str:
    explicit = os.environ.get("AWS_ACCOUNT_ID")
    if explicit:
        return explicit.strip()
    result = subprocess.run(
        ["aws", "sts", "get-caller-identity", "--query", "Account", "--output", "text"],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("template", type=Path)
    args = parser.parse_args()
    text = args.template.read_text()
    marker = "${AWS_ACCOUNT_ID}"
    if marker not in text:
        raise SystemExit(f"template does not contain {marker}: {args.template}")
    print(text.replace(marker, account_id()), end="")

if __name__ == "__main__":
    main()
