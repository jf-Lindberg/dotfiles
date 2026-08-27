#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh sources each step, so the early exits below must return rather
# than terminate the caller; the exit is the fallback for running the step
# directly, which ShellCheck cannot see and reports as unreachable.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITERM_DIR="$REPO/iterm2"
DOMAIN="com.googlecode.iterm2"

if [ ! -f "$ITERM_DIR/$DOMAIN.plist" ]; then
  echo "iterm2: no exported settings at $ITERM_DIR; run scripts/iterm2-export.sh on the old machine first"
  # shellcheck disable=SC2317
  return 0 2>/dev/null || exit 0
fi

# iTerm2 keeps preferences in memory and rewrites them on quit. Pointing a
# running instance at the custom folder therefore looks like it worked and is
# silently reverted the next time iTerm2 exits.
if pgrep -x iTerm2 >/dev/null 2>&1; then
  echo "iterm2: iTerm2 is running; quit it and rerun this step to load settings from $ITERM_DIR"
  # shellcheck disable=SC2317
  return 0 2>/dev/null || exit 0
fi

# Read the settings from the repository instead of copying them in, so future
# changes made through iTerm2's own UI are written back to the checkout.
defaults write "$DOMAIN" PrefsCustomFolder -string "$ITERM_DIR"
defaults write "$DOMAIN" LoadPrefsFromCustomFolder -bool true

# Without this iTerm2 prompts on every quit instead of saving the export.
defaults write "$DOMAIN" NoSyncNeverRemindPrefsChangesLostForFile_selection -integer 2
defaults write "$DOMAIN" NoSyncNeverRemindPrefsChangesLostForFile -bool true

echo "iterm2: loading settings from $ITERM_DIR"
