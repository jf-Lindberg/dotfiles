#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found; installing it now"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ ! -x /opt/homebrew/bin/brew ]; then
  echo "Expected Homebrew at /opt/homebrew/bin/brew (this setup targets Apple Silicon)" >&2
  exit 1
fi

# Keep Homebrew available to the rest of bootstrap.sh, which sources this file.
eval "$(/opt/homebrew/bin/brew shellenv)"
