#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for step in "$REPO"/steps/[0-9][0-9]-*.sh; do
  echo
  echo "==> $(basename "$step")"
  # Source each step so 10-homebrew.sh can update PATH for later steps.
  # shellcheck source=/dev/null
  source "$step"
done

echo
# Keep the operational manual tail in a dedicated file. Printing the same file
# humans read prevents an implementation brief heading from breaking setup.
CHECKLIST="$REPO/docs/post-bootstrap-checklist.md"
if [ ! -s "$CHECKLIST" ]; then
  echo "bootstrap: post-bootstrap checklist is missing or empty: $CHECKLIST" >&2
  exit 1
fi

cat "$CHECKLIST"
