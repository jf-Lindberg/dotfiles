#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-settings.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

grep -qF 'source "$HOME/dev/worklog/config/shell/aliases.sh"' \
  "$ROOT/home/.zshrc"
grep -qF '"$HOME/dev/worklog/scripts/setup.sh" --no-settings --no-aliases' \
  "$ROOT/steps/70-worklog.sh"
grep -qF '"$ENGINEERING_ROOT/scripts/setup.sh" --no-settings' \
  "$ROOT/steps/75-engineering-system.sh"
if grep -Eq '^[[:space:]]*"\$ENGINEERING_ROOT/scripts/setup\.sh"' \
  "$ROOT/steps/80-claude-settings.sh"; then
  echo "Claude settings step must not run Engineering System setup" >&2
  exit 1
fi

STEP_HOME="$WORK/step-home"
mkdir -p "$STEP_HOME/dev/repos/engineering-system/scripts"
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "$*" >"$HOME/setup-args"' \
  >"$STEP_HOME/dev/repos/engineering-system/scripts/setup.sh"
chmod +x "$STEP_HOME/dev/repos/engineering-system/scripts/setup.sh"
HOME="$STEP_HOME" bash "$ROOT/steps/75-engineering-system.sh"
grep -q '^--no-settings$' "$STEP_HOME/setup-args"

SETTINGS="$WORK/settings.json"
STATE="$WORK/state/claude-settings.json"
WORKLOG="$WORK/worklog"
ENGINEERING="$WORK/engineering-system"
REPOSITORY="$WORK/repository"

mkdir -p "$WORKLOG/scripts" "$ENGINEERING" "$REPOSITORY"
printf '{"theme":"dark","permissions":{"additionalDirectories":["/keep"]}}\n' \
  >"$SETTINGS"

python3 "$ROOT/scripts/reconcile-claude-settings.py" \
  --settings "$SETTINGS" \
  --state "$STATE" \
  --worklog "$WORKLOG" \
  --directory "$ENGINEERING" \
  --directory "$REPOSITORY" >/dev/null

python3 - "$SETTINGS" "$STATE" "$WORKLOG" "$ENGINEERING" "$REPOSITORY" <<'PY'
import json
import os
import sys

settings = json.load(open(sys.argv[1]))
state = json.load(open(sys.argv[2]))
worklog, engineering, repository = sys.argv[3:]
directories = settings["permissions"]["additionalDirectories"]
assert settings["theme"] == "dark"
assert "/keep" in directories
assert all(path in directories for path in (worklog, engineering, repository))
assert state["ownedDirectories"] == [worklog, engineering, repository]
command = os.path.join(worklog, "scripts", "cadence.sh")
assert state["ownedHooks"] == [command]
entries = settings["hooks"]["UserPromptSubmit"]
commands = [
    entry["command"]
    for matcher in entries
    for entry in matcher.get("hooks", [])
]
assert commands.count(command) == 1
PY

# Idempotence: no duplicate directory or hook entries.
python3 "$ROOT/scripts/reconcile-claude-settings.py" \
  --settings "$SETTINGS" \
  --state "$STATE" \
  --worklog "$WORKLOG" \
  --directory "$ENGINEERING" \
  --directory "$REPOSITORY" >/dev/null

# Removing a declaration retracts only the central owner's stale entry.
python3 "$ROOT/scripts/reconcile-claude-settings.py" \
  --settings "$SETTINGS" \
  --state "$STATE" \
  --worklog "$WORKLOG" \
  --directory "$ENGINEERING" >/dev/null

python3 - "$SETTINGS" "$WORKLOG" "$ENGINEERING" "$REPOSITORY" <<'PY'
import json
import os
import sys

settings = json.load(open(sys.argv[1]))
worklog, engineering, repository = sys.argv[2:]
directories = settings["permissions"]["additionalDirectories"]
assert directories.count(worklog) == 1
assert directories.count(engineering) == 1
assert repository not in directories
assert "/keep" in directories
command = os.path.join(worklog, "scripts", "cadence.sh")
commands = [
    entry["command"]
    for matcher in settings["hooks"]["UserPromptSubmit"]
    for entry in matcher.get("hooks", [])
]
assert commands.count(command) == 1
PY

# Malformed settings are rejected without being overwritten.
printf 'not json\n' >"$SETTINGS"
if python3 "$ROOT/scripts/reconcile-claude-settings.py" \
  --settings "$SETTINGS" \
  --state "$STATE" \
  --worklog "$WORKLOG" >/dev/null 2>&1; then
  echo "malformed settings unexpectedly succeeded" >&2
  exit 1
fi
grep -q '^not json$' "$SETTINGS"

echo "test-claude-settings PASS"
