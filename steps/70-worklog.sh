#!/usr/bin/env bash
set -euo pipefail

WORKLOG_ROOT="$HOME/dev/repos/worklog"

# Worklog is an ordinary checkout; its private data lives outside the repository
# in its own data directory, resolved by setup.sh.
if [ ! -d "$WORKLOG_ROOT" ]; then
  mkdir -p "$(dirname "$WORKLOG_ROOT")"
  git clone https://github.com/jf-Lindberg/worklog.git "$WORKLOG_ROOT"
fi

# Dotfiles owns settings.json and sources the aliases from home/.zshrc, so
# Worklog installs neither.
"$WORKLOG_ROOT/scripts/setup.sh" --no-settings --no-aliases
