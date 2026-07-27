#!/usr/bin/env bash
# Run the $HOME-relative bootstrap steps against a sandbox HOME.
#
# Steps 30/50/70/75/80 derive every target from $HOME, so they can run against
# a throwaway directory without touching the real home. Steps 10/20/40/60 are
# excluded: Homebrew, oh-my-zsh, and mise install to machine-global locations
# that no $HOME override relocates, so a sandbox cannot exercise them honestly.
# A fresh-machine run is the only way to cover those; see docs/vm-testing.md.
#
# Network clones are replaced by local fixtures. The goal is the repository's
# own logic — linking, backup, tilde expansion, settings reconciliation — not
# the availability of GitHub.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-sandbox.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# home/ holds dotfiles; without dotglob the assertion loops below iterate over
# an unexpanded literal glob. Step 30 sets this for itself.
shopt -s dotglob nullglob

FAILURES=0

fail() {
  echo "FAIL: $*" >&2
  FAILURES=$((FAILURES + 1))
}

check() {
  local description="$1"
  shift
  if "$@"; then
    echo "  ok: $description"
  else
    fail "$description"
  fi
}

# --- fixtures -----------------------------------------------------------
# A worklog stand-in that satisfies the contract steps 70 and 80 depend on:
# setup.sh, doctor.sh, and the cadence.sh hook the reconciler installs.
make_worklog_fixture() {
  local target="$1"
  mkdir -p "$target/scripts"
  # shellcheck disable=SC2016  # Fixture source: $* must reach the stub, unexpanded.
  printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "$*" >>"$HOME/worklog-setup-args"' \
    >"$target/scripts/setup.sh"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$target/scripts/doctor.sh"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$target/scripts/cadence.sh"
  chmod +x "$target/scripts/setup.sh" "$target/scripts/doctor.sh" \
    "$target/scripts/cadence.sh"
}

# An engineering-system stand-in with a valid config, so step 80 takes its
# fully-configured branch rather than the --preserve-owned-directories path.
make_engineering_fixture() {
  local target="$1"
  local worklog="$2"
  local extra_repo="$3"
  mkdir -p "$target/scripts"
  # shellcheck disable=SC2016  # Fixture source: $* must reach the stub, unexpanded.
  printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "$*" >>"$HOME/engineering-setup-args"' \
    >"$target/scripts/setup.sh"
  chmod +x "$target/scripts/setup.sh"
  cat >"$target/scripts/config.py" <<PY
#!/usr/bin/env python3
import sys

if "--validate" in sys.argv:
    sys.exit(0)
if "--worklog" in sys.argv:
    print("$worklog")
    sys.exit(0)
if "--repos" in sys.argv:
    print("extra\t$extra_repo")
    sys.exit(0)
sys.exit(1)
PY
}

# Build a sandbox HOME with the fixtures step 70/75/80 expect to find.
new_home() {
  local home="$1"
  mkdir -p "$home/dev/repos"
  make_worklog_fixture "$home/dev/worklog"
  make_engineering_fixture "$home/dev/repos/engineering-system" \
    "$home/dev/worklog" "$home/dev/repos/registered"
  mkdir -p "$home/dev/repos/registered"
}

# Steps 70 and 80 are the two that reach outside $HOME (a GitHub clone and the
# real doctor). Run the sandbox against a copy of steps/ with the clone removed
# so an unattended run stays offline and deterministic.
# Steps resolve REPO as their own parent, so the copy needs the repository
# files they read (repos.txt, docs/, scripts/) alongside it.
SANDBOX_REPO="$WORK/repo"
STEPS="$SANDBOX_REPO/steps"
mkdir -p "$STEPS"
cp "$ROOT"/steps/[0-9][0-9]-*.sh "$STEPS/"
cp "$ROOT/repos.txt" "$SANDBOX_REPO/"
cp -R "$ROOT/scripts" "$SANDBOX_REPO/"
cp -R "$ROOT/home" "$SANDBOX_REPO/"
cp -R "$ROOT/config" "$SANDBOX_REPO/"

python3 - "$STEPS/70-worklog.sh" <<'PY'
import re
import sys

path = sys.argv[1]
source = open(path, encoding="utf-8").read()
# Replace the network install with a no-op; the fixture worklog already exists.
source = re.sub(
    r"if \[ -d \"\$HOME/\.local/share/worklog\.git\".*?\nfi\n",
    'echo "worklog: sandbox fixture in place"\n',
    source,
    flags=re.DOTALL,
)
open(path, "w", encoding="utf-8").write(source)
PY

run_step() {
  local home="$1"
  local step="$2"
  HOME="$home" bash "$STEPS/$step"
}

# --- 1. clean run -------------------------------------------------------
echo "== clean run =="
H1="$WORK/home1"
new_home "$H1"

run_step "$H1" 30-dotfiles.sh >"$WORK/30.log" 2>&1 ||
  fail "step 30 exited non-zero"

# Step 30 records the repository as cd+pwd sees it. $TMPDIR ends in a slash on
# macOS, so the raw variable can differ from that by a doubled separator;
# normalise the same way the step does before comparing.
SANDBOX_REPO_REAL="$(cd "$SANDBOX_REPO" && pwd)"
for item in "$SANDBOX_REPO"/home/*; do
  name="$(basename "$item")"
  # shellcheck disable=SC2088  # Tildes below are prose in test descriptions.
  check "linked ~/$name" [ -L "$H1/$name" ]
  # shellcheck disable=SC2088  # Tilde is prose in the description.
  check "~/$name resolves into the repo" \
    [ "$(readlink "$H1/$name")" = "$SANDBOX_REPO_REAL/home/$name" ]
done

for item in "$SANDBOX_REPO"/config/*; do
  name="$(basename "$item")"
  check "linked ~/.config/$name" [ -L "$H1/.config/$name" ]
done

run_step "$H1" 50-repos.sh >"$WORK/50.log" 2>&1 ||
  fail "step 50 exited non-zero"
check "step 50 created ~/dev/go" [ -d "$H1/dev/go" ]

run_step "$H1" 70-worklog.sh >"$WORK/70.log" 2>&1 ||
  fail "step 70 exited non-zero"
check "step 70 called worklog setup with --no-settings --no-aliases" \
  grep -qF -- '--no-settings --no-aliases' "$H1/worklog-setup-args"

run_step "$H1" 75-engineering-system.sh >"$WORK/75.log" 2>&1 ||
  fail "step 75 exited non-zero"
check "step 75 called engineering setup with --no-settings" \
  grep -qxF -- '--no-settings' "$H1/engineering-setup-args"

run_step "$H1" 80-claude-settings.sh >"$WORK/80.log" 2>&1 ||
  fail "step 80 exited non-zero"
check "step 80 wrote settings.json" [ -f "$H1/.claude/settings.json" ]
check "step 80 wrote its state file" \
  [ -f "$H1/.local/state/dotfiles/claude-settings.json" ]
check "step 80 did not re-run engineering setup" \
  [ "$(grep -c . "$H1/engineering-setup-args")" = "1" ]

if python3 - "$H1" >"$WORK/grants.log" 2>&1 <<'PY'; then
import json
import os
import sys

home = sys.argv[1]
settings = json.load(open(os.path.join(home, ".claude", "settings.json")))
state = json.load(
    open(os.path.join(home, ".local", "state", "dotfiles", "claude-settings.json"))
)
directories = settings["permissions"]["additionalDirectories"]
expected = [
    os.path.join(home, "dev", "worklog"),
    os.path.join(home, "dev", "repos", "engineering-system"),
    os.path.join(home, "dev", "repos", "registered"),
]
missing = [path for path in expected if path not in directories]
assert not missing, "missing grants: %s" % missing
hook = os.path.join(home, "dev", "worklog", "scripts", "cadence.sh")
assert state["ownedHooks"] == [hook], state["ownedHooks"]
commands = [
    entry["command"]
    for matcher in settings["hooks"]["UserPromptSubmit"]
    for entry in matcher.get("hooks", [])
]
assert commands.count(hook) == 1, commands
PY
  echo "  ok: step 80 granted worklog, engineering, and registered repos"
else
  fail "step 80 grants or cadence hook are wrong"
  cat "$WORK/grants.log" >&2
fi

# --- 2. idempotence -----------------------------------------------------
# The strongest signal available in a sandbox: a second run must add no
# backups and change no file content.
echo "== idempotence =="
snapshot() {
  local home="$1"
  local out="$2"
  # Exclude the timestamped settings backup step 80 makes by design, and the
  # append-only fixture argument logs.
  (cd "$home" && find . \
    -not -path './.claude/settings.json.backup-*' \
    -not -name 'worklog-setup-args' \
    -not -name 'engineering-setup-args' |
    sort) >"$out.list"
  (cd "$home" && find . -type f \
    -not -path './.claude/settings.json.backup-*' \
    -not -name 'worklog-setup-args' \
    -not -name 'engineering-setup-args' \
    -exec shasum {} \; | sort -k2) >"$out.sums"
}

snapshot "$H1" "$WORK/before"
for step in 30-dotfiles.sh 50-repos.sh 70-worklog.sh 75-engineering-system.sh \
  80-claude-settings.sh; do
  run_step "$H1" "$step" >"$WORK/rerun-$step.log" 2>&1 ||
    fail "second run of $step exited non-zero"
done
snapshot "$H1" "$WORK/after"

if diff -u "$WORK/before.list" "$WORK/after.list" >"$WORK/list.diff"; then
  echo "  ok: second run created no new paths"
else
  fail "second run changed the file tree"
  cat "$WORK/list.diff" >&2
fi

if diff -u "$WORK/before.sums" "$WORK/after.sums" >"$WORK/sums.diff"; then
  echo "  ok: second run changed no file contents"
else
  fail "second run rewrote file contents"
  cat "$WORK/sums.diff" >&2
fi

check "second run created no .bak-* files" \
  [ -z "$(find "$H1" -name '*.bak-*' -print -quit)" ]

# --- 3. adoption of pre-existing files ----------------------------------
# A real machine is not empty: step 30 must back up what it replaces, exactly
# once, and leave the backup's content intact.
echo "== adoption of existing files =="
H2="$WORK/home2"
new_home "$H2"
printf 'pre-existing zshrc\n' >"$H2/.zshrc"
mkdir -p "$H2/.config"
printf 'pre-existing starship\n' >"$H2/.config/starship.toml"

run_step "$H2" 30-dotfiles.sh >"$WORK/30-adopt.log" 2>&1 ||
  fail "step 30 exited non-zero adopting existing files"

# shellcheck disable=SC2088  # Tilde is prose in the description.
check "~/.zshrc replaced with a link" [ -L "$H2/.zshrc" ]
backup="$(find "$H2" -maxdepth 1 -name '.zshrc.bak-*' | head -1)"
check "original .zshrc backed up" [ -n "$backup" ]
if [ -n "$backup" ]; then
  check "backup kept the original content" \
    grep -qx 'pre-existing zshrc' "$backup"
fi
config_backup="$(find "$H2/.config" -maxdepth 1 -name 'starship.toml.bak-*' | head -1)"
check "original .config/starship.toml backed up" [ -n "$config_backup" ]

# --- 4. repos.txt parsing -----------------------------------------------
# repos.txt ships comment-only, so the tab parsing and literal ~/ expansion
# in step 50 are otherwise never executed.
echo "== repos.txt parsing =="
H3="$WORK/home3"
new_home "$H3"
SOURCE_REPO="$WORK/source-repo"
mkdir -p "$SOURCE_REPO"
git -C "$SOURCE_REPO" init -q
git -C "$SOURCE_REPO" config user.email sandbox@example.com
git -C "$SOURCE_REPO" config user.name Sandbox
printf 'fixture\n' >"$SOURCE_REPO/README.md"
git -C "$SOURCE_REPO" add README.md
git -C "$SOURCE_REPO" -c commit.gpgsign=false commit -qm "fixture"

FIXTURE_ROOT="$WORK/fixture-root"
mkdir -p "$FIXTURE_ROOT/steps"
cp "$STEPS/50-repos.sh" "$FIXTURE_ROOT/steps/"
printf '# comment line\n\n%s\t~/dev/repos/tilde-target\n' "$SOURCE_REPO" \
  >"$FIXTURE_ROOT/repos.txt"

HOME="$H3" bash "$FIXTURE_ROOT/steps/50-repos.sh" >"$WORK/50-fixture.log" 2>&1 ||
  fail "step 50 exited non-zero with a populated repos.txt"
check "literal ~/ expanded to the sandbox HOME" \
  [ -d "$H3/dev/repos/tilde-target" ]
check "clone produced the fixture content" \
  [ -f "$H3/dev/repos/tilde-target/README.md" ]

HOME="$H3" bash "$FIXTURE_ROOT/steps/50-repos.sh" >"$WORK/50-fixture2.log" 2>&1 ||
  fail "second step 50 run exited non-zero"
check "existing clone reported as already present" \
  grep -q 'already present' "$WORK/50-fixture2.log"

printf '%s\n' "$SOURCE_REPO" >"$FIXTURE_ROOT/repos.txt"
if HOME="$H3" bash "$FIXTURE_ROOT/steps/50-repos.sh" >"$WORK/50-bad.log" 2>&1; then
  fail "step 50 accepted a repos.txt line with no tab-separated target"
else
  echo "  ok: missing tab-separated target rejected"
fi

# --- 5. ordering contract -----------------------------------------------
# 60-runtimes.sh reads ~/.config/mise/config.toml, which step 30 links. The
# documented ordering is load-bearing, so prove step 60's input does not exist
# before step 30 runs.
echo "== ordering contract =="
H4="$WORK/home4"
new_home "$H4"
check "mise config absent before step 30" \
  [ ! -e "$H4/.config/mise/config.toml" ]
run_step "$H4" 30-dotfiles.sh >"$WORK/30-order.log" 2>&1 ||
  fail "step 30 exited non-zero"
check "step 30 supplies the mise config step 60 reads" \
  [ -f "$H4/.config/mise/config.toml" ]

# --- 6. manual checklist extraction -------------------------------------
# bootstrap.sh awk-extracts Phase 11 from the plan. A renamed heading would
# silently print nothing and still exit 0.
echo "== manual checklist =="
CHECKLIST="$(awk '
  /^## Phase 11 —/ { printing = 1; next }
  printing && /^---$/ { exit }
  printing { print }
' "$ROOT/docs/dotfiles-setup-plan.md")"
check "Phase 11 checklist is non-empty" [ -n "$CHECKLIST" ]
check "Phase 11 checklist has real content" \
  [ "$(printf '%s\n' "$CHECKLIST" | wc -l | tr -d ' ')" -gt 10 ]

# --- result -------------------------------------------------------------
echo
if [ "$FAILURES" -eq 0 ]; then
  echo "test-bootstrap-sandbox PASS"
else
  echo "test-bootstrap-sandbox FAIL ($FAILURES)" >&2
  exit 1
fi
