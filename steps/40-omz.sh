#!/usr/bin/env bash
set -euo pipefail

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh: already installed"
else
  KEEP_ZSHRC=yes RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
