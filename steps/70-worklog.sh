#!/usr/bin/env bash
set -euo pipefail

if [ -d "$HOME/.local/share/worklog.git" ] && [ -d "$HOME/dev/worklog" ]; then
  echo "worklog: already installed, skipping mirror install"
else
  git clone https://github.com/jf-Lindberg/worklog.git /tmp/worklog-installer
  /tmp/worklog-installer/scripts/install-mirror.sh \
    --remote https://github.com/jf-Lindberg/worklog.git
  rm -rf /tmp/worklog-installer # ONLY destructive command in bootstrap; fixed literal path
fi

"$HOME/dev/worklog/scripts/setup.sh" --no-settings --no-aliases
