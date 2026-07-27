#!/usr/bin/env bash
set -euo pipefail

# Versions come from ~/.config/mise/config.toml, symlinked by 30-dotfiles.sh.
# That symlink must already exist, so keep step 30 before this one.
mise install
mise reshim

# tsx as an npm global under the mise-managed default node (see caveat below).
mise exec node -- npm install -g tsx
mise reshim
