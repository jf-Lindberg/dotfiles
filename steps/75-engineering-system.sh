#!/usr/bin/env bash
set -euo pipefail

ENGINEERING_ROOT="$HOME/dev/repos/engineering-system"

if [ -x "$ENGINEERING_ROOT/scripts/setup.sh" ]; then
  # Dotfiles owns settings.json; Engineering System installs only its links and
  # relinquishes any ownership left by an older standalone installation.
  "$ENGINEERING_ROOT/scripts/setup.sh" --no-settings
else
  echo "engineering-system: not present at $ENGINEERING_ROOT; add its remote to repos.txt to install it"
fi
