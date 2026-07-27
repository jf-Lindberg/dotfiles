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
# Phase 11 in the implementation brief is the single source of truth for the
# manual tail. Print it verbatim so the documentation and terminal checklist
# cannot drift apart.
CHECKLIST="$(awk '
  /^## Phase 11 —/ { printing = 1; next }
  printing && /^---$/ { exit }
  printing { print }
' "$REPO/docs/dotfiles-setup-plan.md")"

# An edited heading would otherwise leave bootstrap silently printing nothing
# and still exiting 0, hiding the manual steps that finish the install.
if [ -z "$CHECKLIST" ]; then
  echo "bootstrap: could not extract the Phase 11 checklist from" \
    "docs/dotfiles-setup-plan.md; complete the manual steps from that file" >&2
  exit 1
fi

printf '%s\n' "$CHECKLIST"
