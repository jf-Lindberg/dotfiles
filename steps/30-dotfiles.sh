#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# Include the dotfiles under home/ in the first glob and make empty globs vanish.
shopt -s dotglob nullglob

backup_path() {
  local target="$1"
  local backup="${target}.bak-${TIMESTAMP}"
  local sequence=1

  while [ -e "$backup" ] || [ -L "$backup" ]; do
    backup="${target}.bak-${TIMESTAMP}-${sequence}"
    sequence=$((sequence + 1))
  done

  printf '%s\n' "$backup"
}

link_item() {
  local source="$1"
  local target="$2"
  local current backup

  if [ -L "$target" ]; then
    current="$(readlink "$target")"
    if [ "$current" = "$source" ]; then
      echo "dotfiles: already linked $target"
      return
    fi
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    backup="$(backup_path "$target")"
    echo "dotfiles: backing up $target to $backup"
    mv "$target" "$backup"
  fi

  echo "dotfiles: linking $target -> $source"
  ln -s "$source" "$target"
}

mkdir -p "$HOME/.config"

for source in "$REPO"/home/*; do
  link_item "$source" "$HOME/$(basename "$source")"
done

for source in "$REPO"/config/*; do
  link_item "$source" "$HOME/.config/$(basename "$source")"
done
