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

# Go
export GOPATH="$HOME/dev/go"
export GOBIN="$HOME/.local/bin"

# PATH — $HOME/.local/bin holds GOBIN output and the claude binary
export PATH="$HOME/.local/bin:$PATH"

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

# worklog aliases are appended below by worklog's scripts/setup.sh
