#!/bin/sh
set -e
cd "$(dirname "$0")/.."
if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required to generate Secrets.generated.swift" >&2
  exit 1
fi
python3 scripts/generate_ios_secrets.py
