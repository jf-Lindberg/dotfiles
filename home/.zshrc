# Homebrew completions on fpath BEFORE oh-my-zsh runs compinit,
# so brew-installed tools (gh, docker, …) get tab-completion.
if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# oh-my-zsh — kept for completion (compinit) and the git plugin's aliases.
# Prompt is handled by starship at the bottom of this file, so the theme is empty.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""              # prompt comes from starship, initialised below
plugins=(git)             # add wisely — plugins slow startup
source "$ZSH/oh-my-zsh.sh"

# Editor
export EDITOR="nvim"
export VISUAL="nvim"

# Xcode Command Line Tools 26.6 bundles a broken beta SDK (MacOSX27.0.sdk)
# that clang/xcrun pick by default (highest version wins), but whose
# libSystem.tbd declares architecture triples this toolchain's linker can't
# parse ("ld: tapi error: malformed file ... unknown architecture
# arm64e.x1-macos"). Pin to the last known-good SDK until Apple ships a fixed
# CLT release; guarded so this is a no-op once that SDK is gone or on a
# machine that never had it.
if [ -d /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk ]; then
  export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
fi

# Go
export GOPATH="$HOME/dev/go"
export GOBIN="$HOME/.local/bin"

# PATH — $HOME/.local/bin holds GOBIN output and the claude binary;
# $HOME/bin is dotfiles-managed (symlinked from home/bin) and holds hand-written
# scripts such as the iTerm2 semantic-history handler.
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# mise — polyglot runtime manager; owns node, python and go.
# Must come AFTER the PATH export above so mise's shims take precedence over
# both ~/.local/bin and /opt/homebrew/bin.
# Per-project versions come from mise.toml / .tool-versions / .nvmrc.
eval "$(mise activate zsh)"

# Interactive zsh enhancements (installed via Homebrew).
# zsh-syntax-highlighting MUST be sourced last, after autosuggestions.
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Prompt (starship reads ~/.config/starship.toml, symlinked from this repo)
eval "$(starship init zsh)"

# ngrok completions
if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi

# Worklog is installed after this file is linked, so source it conditionally.
if [ -f "$HOME/dev/repos/worklog/config/shell/aliases.sh" ]; then
  source "$HOME/dev/repos/worklog/config/shell/aliases.sh"
fi
