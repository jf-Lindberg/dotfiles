#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-open-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/dir"

cat >"$TEST_ROOT/bin/nvim" <<'EOF'
#!/usr/bin/env bash
printf 'nvim' >>"$CALL_LOG"
printf ' <%s>' "$@" >>"$CALL_LOG"
printf '\n' >>"$CALL_LOG"
EOF

cat >"$TEST_ROOT/bin/system-open" <<'EOF'
#!/usr/bin/env bash
printf 'system-open' >>"$CALL_LOG"
printf ' <%s>' "$@" >>"$CALL_LOG"
printf '\n' >>"$CALL_LOG"
EOF

chmod +x "$TEST_ROOT/bin/nvim" "$TEST_ROOT/bin/system-open"

printf 'plain text\n' >"$TEST_ROOT/notes with spaces.txt"
printf '{"valid": true}\n' >"$TEST_ROOT/data.json"
: >"$TEST_ROOT/empty.txt"
printf '\211PNG\r\n\032\n\000binary' >"$TEST_ROOT/image.png"

export CALL_LOG="$TEST_ROOT/calls.log"
export DOTFILES_NVIM_BIN="$TEST_ROOT/bin/nvim"
export DOTFILES_OPEN_BIN="$TEST_ROOT/bin/system-open"

"$ROOT/home/bin/open" \
  "$TEST_ROOT/notes with spaces.txt" \
  "$TEST_ROOT/data.json" \
  "$TEST_ROOT/empty.txt"
"$ROOT/home/bin/open" "$TEST_ROOT/image.png"
"$ROOT/home/bin/open" "$TEST_ROOT/dir"
"$ROOT/home/bin/open" -R "$TEST_ROOT/notes with spaces.txt"
"$ROOT/home/bin/open" "$TEST_ROOT/image.png" "$TEST_ROOT/data.json"

cat >"$TEST_ROOT/expected.log" <<EOF
nvim <--> <$TEST_ROOT/notes with spaces.txt> <$TEST_ROOT/data.json> <$TEST_ROOT/empty.txt>
system-open <$TEST_ROOT/image.png>
system-open <$TEST_ROOT/dir>
system-open <-R> <$TEST_ROOT/notes with spaces.txt>
system-open <$TEST_ROOT/image.png>
nvim <--> <$TEST_ROOT/data.json>
EOF

diff -u "$TEST_ROOT/expected.log" "$CALL_LOG"
printf 'open wrapper tests passed\n'
