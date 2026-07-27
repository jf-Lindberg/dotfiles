#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKLOG_ROOT="$HOME/dev/worklog"
ENGINEERING_ROOT="$HOME/dev/repos/engineering-system"
SETTINGS_FILE="$HOME/.claude/settings.json"
STATE_FILE="$HOME/.local/state/dotfiles/claude-settings.json"

[ -d "$WORKLOG_ROOT" ] || {
  echo "claude settings: worklog is not installed at $WORKLOG_ROOT" >&2
  exit 1
}

reconcile_args=(
  --settings "$SETTINGS_FILE"
  --state "$STATE_FILE"
  --worklog "$WORKLOG_ROOT"
)

if [ -x "$ENGINEERING_ROOT/scripts/setup.sh" ]; then
  reconcile_args+=(--directory "$ENGINEERING_ROOT")

  if python3 "$ENGINEERING_ROOT/scripts/config.py" \
    "$ENGINEERING_ROOT" --validate >/dev/null 2>&1; then
    configured_worklog="$(
      python3 "$ENGINEERING_ROOT/scripts/config.py" \
        "$ENGINEERING_ROOT" --worklog
    )"
    [ -z "$configured_worklog" ] ||
      reconcile_args+=(--directory "$configured_worklog")

    while IFS=$'\t' read -r _ repository_path; do
      [ -z "$repository_path" ] ||
        reconcile_args+=(--directory "$repository_path")
    done < <(
      python3 "$ENGINEERING_ROOT/scripts/config.py" \
        "$ENGINEERING_ROOT" --repos
    )
  else
    echo "claude settings: Engineering System config is incomplete; preserving prior central grants" >&2
    reconcile_args+=(--preserve-owned-directories)
  fi
fi

mkdir -p "$HOME/.claude" "$(dirname "$STATE_FILE")"
if [ -f "$SETTINGS_FILE" ]; then
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup-$(date +%Y%m%d-%H%M%S)"
fi

python3 "$DOTFILES_ROOT/scripts/reconcile-claude-settings.py" \
  "${reconcile_args[@]}"

if ! "$WORKLOG_ROOT/scripts/doctor.sh"; then
  echo "worklog: doctor reported a problem; review its output above" >&2
fi
