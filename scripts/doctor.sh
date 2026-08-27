#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ONLY=0
FAILURES=0
WARNINGS=0

usage() {
  cat <<'EOF'
Usage: doctor.sh [--repo-only] [--help]

Check the Dotfiles repository and, unless --repo-only is supplied, the installed
Homebrew bundle, links, runtimes, Worklog mirror, Engineering System, and central
Claude settings state. This command never changes the machine.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-only) REPO_ONLY=1 ;;
    --help | -h)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown option: %s (see --help)\n' "$1" >&2
      exit 1
      ;;
  esac
  shift
done

pass() { printf '  PASS  %s\n' "$*"; }
warn() {
  printf '  WARN  %s\n' "$*" >&2
  WARNINGS=$((WARNINGS + 1))
}
fail() {
  printf '  FAIL  %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}
section() { printf '\n==> %s\n' "$*"; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }
resolve_path() { python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"; }

check_link() {
  local source_path="$1"
  local destination_path="$2"
  if [ -L "$destination_path" ] &&
    [ "$(resolve_path "$destination_path")" = "$(resolve_path "$source_path")" ]; then
    pass "$destination_path -> repository source"
  elif [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
    fail "$destination_path exists but does not point to $source_path"
  else
    fail "$destination_path is not linked"
  fi
}

section "Repository checks ($ROOT)"

required_files="
.editorconfig
.gitignore
Brewfile
README.md
bootstrap.sh
justfile
repos.txt
ruff.toml
scripts/doctor.sh
scripts/reconcile-claude-settings.py
scripts/sanitize-iterm2-plist.py
tests/test-bootstrap-sandbox.sh
tests/test-claude-settings.sh
tests/test-git-identity.sh
tests/test-iterm2-portability.sh
"
missing=""
for relative_path in $required_files; do
  [ -f "$ROOT/$relative_path" ] || missing="$missing $relative_path"
done
if [ -z "$missing" ]; then
  pass "Required repository files are present."
else
  fail "Missing repository files:$missing"
fi

non_executable=""
for script_path in \
  "$ROOT/bootstrap.sh" \
  "$ROOT"/scripts/*.sh \
  "$ROOT"/scripts/*.py \
  "$ROOT"/steps/*.sh \
  "$ROOT"/tests/*.sh; do
  [ -x "$script_path" ] || non_executable="$non_executable ${script_path#"$ROOT/"}"
done
if [ -z "$non_executable" ]; then
  pass "Scripts are executable."
else
  fail "Scripts are not executable:$non_executable"
fi

iterm_export="$ROOT/iterm2/com.googlecode.iterm2.plist"
if [ ! -f "$iterm_export" ]; then
  warn "No iTerm2 export in iterm2/; run scripts/iterm2-export.sh on the machine that has the settings."
elif plutil -lint "$iterm_export" >/dev/null 2>&1; then
  if grep -Eq '/Users/[^/]+' "$iterm_export"; then
    fail "iTerm2 settings export contains a machine-specific home path."
  else
    pass "iTerm2 settings export is valid and username-neutral."
  fi
else
  fail "iTerm2 settings export is malformed: $iterm_export"
fi

if [ "$REPO_ONLY" -eq 1 ]; then
  section "Result (repo-only)"
  printf 'Checks failed: %s   Warnings: %s\n' "$FAILURES" "$WARNINGS"
  [ "$FAILURES" -eq 0 ]
  exit
fi

section "Platform and Homebrew"
if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
  pass "Apple Silicon macOS detected."
else
  fail "Expected Apple Silicon macOS; found $(uname -s) $(uname -m)."
fi

if have_cmd brew; then
  if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file="$ROOT/Brewfile" >/dev/null; then
    pass "Homebrew bundle is satisfied."
  else
    fail "Homebrew bundle is incomplete; run brew bundle --file=$ROOT/Brewfile."
  fi
else
  fail "Homebrew is not available."
fi

section "Dotfile links"
if have_cmd python3; then
  shopt -s dotglob nullglob
  for source_path in "$ROOT"/home/*; do
    check_link "$source_path" "$HOME/$(basename "$source_path")"
  done
  for source_path in "$ROOT"/config/*; do
    check_link "$source_path" "$HOME/.config/$(basename "$source_path")"
  done
else
  fail "Python 3 is unavailable; cannot resolve symlink targets."
fi

section "mise runtimes"
if have_cmd mise; then
  missing_mise=""
  for runtime_name in node python go; do
    mise current "$runtime_name" >/dev/null 2>&1 ||
      missing_mise="$missing_mise $runtime_name"
  done
  if [ -z "$missing_mise" ]; then
    pass "mise reports node, python, and go as installed."
  else
    fail "mise does not report configured runtimes:$missing_mise"
  fi
else
  fail "mise is not available."
fi

for runtime_command in node python3 go; do
  if ! have_cmd "$runtime_command"; then
    fail "$runtime_command is not available."
    continue
  fi
  runtime_path="$(command -v "$runtime_command")"
  case "$runtime_path" in
    "$HOME/.local/share/mise/installs/"*)
      pass "$runtime_command resolves through mise."
      ;;
    *)
      fail "$runtime_command resolves outside mise: $runtime_path"
      ;;
  esac
done

section "Worklog"
WORKLOG_ROOT="$HOME/dev/repos/worklog"
if [ ! -x "$WORKLOG_ROOT/scripts/doctor.sh" ]; then
  fail "Worklog doctor is absent at $WORKLOG_ROOT/scripts/doctor.sh."
elif [ ! -e "$WORKLOG_ROOT/.git" ]; then
  fail "Worklog has no .git; the expected installation is an ordinary checkout."
elif "$WORKLOG_ROOT/scripts/doctor.sh"; then
  pass "Worklog repository and integration are healthy."
else
  fail "Worklog doctor reported problems."
fi

section "Engineering System"
ENGINEERING_ROOT="$HOME/dev/repos/engineering-system"
if [ ! -d "$ENGINEERING_ROOT" ]; then
  warn "Engineering System is not cloned at $ENGINEERING_ROOT."
elif [ ! -x "$ENGINEERING_ROOT/scripts/doctor.sh" ]; then
  fail "Engineering System doctor is absent or not executable."
elif "$ENGINEERING_ROOT/scripts/doctor.sh"; then
  pass "Engineering System repository and integration are healthy."
else
  fail "Engineering System doctor reported problems."
fi

section "Central Claude settings state"
SETTINGS_FILE="$HOME/.claude/settings.json"
STATE_FILE="$HOME/.local/state/dotfiles/claude-settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
  fail "Claude settings are absent at $SETTINGS_FILE."
elif [ ! -f "$STATE_FILE" ]; then
  fail "Dotfiles settings ownership state is absent at $STATE_FILE."
elif python3 - "$SETTINGS_FILE" "$STATE_FILE" <<'PY'; then
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    settings = json.load(handle)
with open(sys.argv[2], encoding="utf-8") as handle:
    state = json.load(handle)

assert isinstance(settings, dict)
assert isinstance(state, dict)
directories = state.get("ownedDirectories", [])
hooks = state.get("ownedHooks", [])
assert isinstance(directories, list)
assert all(isinstance(path, str) for path in directories)
assert isinstance(hooks, list)
assert all(isinstance(hook, str) for hook in hooks)
PY
  pass "Claude settings and Dotfiles ownership state are valid JSON."
else
  fail "Claude settings or Dotfiles ownership state is malformed."
fi

section "iTerm2"
if [ ! -f "$ROOT/iterm2/com.googlecode.iterm2.plist" ]; then
  warn "No iTerm2 export to load; see scripts/iterm2-export.sh."
elif [ "$(defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder 2>/dev/null || echo 0)" != "1" ]; then
  warn "iTerm2 is not loading settings from the checkout; quit iTerm2 and run steps/35-iterm2.sh."
elif [ "$(resolve_path "$(defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null || echo /nonexistent)")" = "$(resolve_path "$ROOT/iterm2")" ]; then
  pass "iTerm2 loads settings from the checkout."
else
  fail "iTerm2 loads settings from a folder outside this repository."
fi

section "Result"
printf 'Checks failed: %s   Warnings: %s\n' "$FAILURES" "$WARNINGS"
[ "$FAILURES" -eq 0 ]
