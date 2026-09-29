#!/bin/sh
set -e
cd "$(dirname "$0")/.."

ENV_FILE="Luma/Config/.env"
GENERATED_FILE="Luma/Config/Secrets.generated.swift"

if [ ! -f "$ENV_FILE" ] && [ -s "$GENERATED_FILE" ]; then
  echo "warning: $ENV_FILE is missing; using the existing $GENERATED_FILE."
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required to generate Secrets.generated.swift" >&2
  exit 1
fi
python3 scripts/generate_ios_secrets.py
