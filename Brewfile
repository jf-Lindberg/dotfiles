tap "hashicorp/tap"

# --- shell / prompt ---
brew "starship"                 # prompt (reads ~/.config/starship.toml)
brew "zsh-autosuggestions"      # interactive: fish-style suggestions
brew "zsh-syntax-highlighting"  # interactive: must be sourced LAST in .zshrc

# --- core CLI ---
brew "git"
brew "gh"
brew "jq"
brew "yq"
brew "ripgrep"
brew "fd"
brew "ast-grep"
brew "just"
brew "onefetch"               # engineering-system: derive-repo.sh reads its JSON output
brew "tmux"
brew "neovim"
brew "tree-sitter-cli"        # nvim treesitter dependency
brew "lazygit"

# --- shell scripting ---
brew "shellcheck"
brew "shfmt"

# --- languages ---
brew "mise"                   # owns node + python + go; see steps/60-runtimes.sh
brew "uv"                     # Python projects: venvs, lockfiles, uvx
# deliberately NOT node, NOT go, NOT fnm — mise owns all runtimes, see README

# --- cloud / infra ---
brew "kubernetes-cli"         # provides `kubectl`
brew "k9s"
brew "awscli"                 # provides `aws`
brew "hashicorp/tap/terraform"

# --- fonts ---
cask "font-meslo-lg-nerd-font"   # Nerd Font: starship.toml uses glyphs ( ☸ …); any Nerd Font works

# --- GUI ---
cask "iterm2"
cask "alfred"
cask "thaw"                   # menu bar manager (Thaw) — free/OSS, replaced Bartender
cask "spotify"
cask "claude"                 # Claude Desktop
cask "claude-code"
cask "docker-desktop"
