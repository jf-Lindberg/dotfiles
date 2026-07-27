#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$HOME/dev/repos" "$HOME/dev/go"

while IFS=$'\t' read -r url target || [ -n "$url" ]; do
  if [ -z "$url" ] || [[ "$url" = \#* ]]; then
    continue
  fi

  if [ -z "${target:-}" ]; then
    echo "repos.txt: missing tab-separated target for $url" >&2
    exit 1
  fi

  # A literal ~/ prefix is convenient in the manifest but is not expanded
  # automatically when read from a file.
  # shellcheck disable=SC2088  # The tilde is intentionally literal here.
  tilde_prefix="~/"
  if [[ "$target" = "$tilde_prefix"* ]]; then
    target="$HOME/${target#"$tilde_prefix"}"
  fi

  if [ -d "$target" ]; then
    echo "repos: already present $target"
    continue
  fi

  mkdir -p "$(dirname "$target")"
  git clone "$url" "$target"
done <"$REPO/repos.txt"
