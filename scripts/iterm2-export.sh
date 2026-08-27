#!/usr/bin/env bash
set -euo pipefail

# Snapshot the live iTerm2 preferences into the repository.
#
# This exists for the machine that is not yet reading its settings from the
# checkout. Once steps/35-iterm2.sh has pointed iTerm2 at iterm2/, iTerm2
# writes that file itself and this script is redundant.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOMAIN="com.googlecode.iterm2"
SOURCE="$HOME/Library/Preferences/$DOMAIN.plist"
TARGET="$REPO/iterm2/$DOMAIN.plist"

if [ ! -f "$SOURCE" ]; then
  echo "iterm2-export: no preferences found at $SOURCE" >&2
  exit 1
fi

# Ask a running iTerm2 to flush its in-memory preferences first, otherwise the
# export silently captures the state from the last time it quit.
if pgrep -x iTerm2 >/dev/null 2>&1; then
  echo "iterm2-export: iTerm2 is running; recent changes are exported only after it writes them out"
  defaults read "$DOMAIN" >/dev/null 2>&1 || true
fi

mkdir -p "$REPO/iterm2"

# Convert to XML so the export produces reviewable diffs rather than a binary
# blob that every settings change rewrites wholesale.
plutil -convert xml1 -o "$TARGET" "$SOURCE"
python3 "$REPO/scripts/sanitize-iterm2-plist.py" \
  --home "$HOME" "$TARGET"
plutil -lint "$TARGET" >/dev/null

echo "iterm2-export: wrote $TARGET"
