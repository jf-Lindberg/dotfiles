#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-iterm2.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

FIXTURE="$WORK/preferences.plist"
python3 - "$FIXTURE" <<'PY'
import plistlib
import sys

preferences = {
    "New Bookmarks": [
        {
            "Semantic History": {
                "action": "command",
                "text": r"/Users/example/bin/it2nvim-split \1 \2",
            },
            "Working Directory": "/Users/example/dev",
        }
    ]
}
with open(sys.argv[1], "wb") as handle:
    plistlib.dump(preferences, handle)
PY

python3 "$ROOT/scripts/sanitize-iterm2-plist.py" \
  --home /Users/example "$FIXTURE"

python3 - "$FIXTURE" <<'PY'
import plistlib
import sys

with open(sys.argv[1], "rb") as handle:
    profile = plistlib.load(handle)["New Bookmarks"][0]
assert profile["Semantic History"]["text"] == r"$HOME/bin/it2nvim-split \1 \2"
assert profile["Working Directory"] == "~/dev"
assert "/Users/example" not in repr(profile)
PY

# The committed export must already pass the same transformation without a
# source-tree rewrite, and it must not carry this machine's literal home path.
cp "$ROOT/iterm2/com.googlecode.iterm2.plist" "$WORK/committed.plist"
python3 "$ROOT/scripts/sanitize-iterm2-plist.py" \
  --home "$HOME" "$WORK/committed.plist"
if grep -qF "$HOME" "$ROOT/iterm2/com.googlecode.iterm2.plist"; then
  echo "committed iTerm2 export contains the current machine's home path" >&2
  exit 1
fi

echo "test-iterm2-portability PASS"
