#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not on PATH; run steps/10-homebrew.sh first" >&2
  exit 1
fi

brew bundle --file="$REPO/Brewfile"
