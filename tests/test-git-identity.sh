#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-git-identity.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

TEST_HOME="$WORK/home"
mkdir -p "$TEST_HOME/dev/repos/tool" "$TEST_HOME/dev/personal/project" \
  "$TEST_HOME/dev/work/project" "$TEST_HOME/elsewhere"
cp "$ROOT/home/.gitconfig" "$TEST_HOME/.gitconfig"
cp "$ROOT/home/.gitconfig-personal" "$TEST_HOME/.gitconfig-personal"
cp "$ROOT/home/.gitconfig-work" "$TEST_HOME/.gitconfig-work"
printf '%s\n' '[user]' '  name = Work Person' '  email = work@example.test' \
  >"$TEST_HOME/.gitconfig-work-local"

for repository in \
  "$TEST_HOME/dev/repos/tool" \
  "$TEST_HOME/dev/personal/project" \
  "$TEST_HOME/dev/work/project" \
  "$TEST_HOME/elsewhere"; do
  git -C "$repository" init -q
done

git_config() {
  HOME="$TEST_HOME" GIT_CONFIG_NOSYSTEM=1 git -C "$1" config "$2" 2>/dev/null || true
}

[ "$(git_config "$TEST_HOME/dev/repos/tool" user.email)" = \
  "jakob.filip.lindberg@gmail.com" ]
[ "$(git_config "$TEST_HOME/dev/personal/project" user.email)" = \
  "jakob.filip.lindberg@gmail.com" ]
[ "$(git_config "$TEST_HOME/dev/work/project" user.email)" = \
  "work@example.test" ]
[ -z "$(git_config "$TEST_HOME/elsewhere" user.email)" ]

if grep -En 'WORK_EMAIL_PLACEHOLDER|work@example\.test' \
  "$ROOT/home/.gitconfig" "$ROOT/home/.gitconfig-work"; then
  echo "tracked Git dispatcher contains a work identity or placeholder" >&2
  exit 1
fi

echo "test-git-identity PASS"
