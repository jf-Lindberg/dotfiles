# Post-bootstrap checklist

Complete these steps after `./bootstrap.sh`. The bootstrap prints this file
verbatim; this is the operational source of truth for the manual tail.

## 1. Configure the local work Git identity

Tracked Dotfiles never contains an employer name or email. Repositories under
`~/dev/repos` and `~/dev/personal` use the tracked personal identity, while
repositories under `~/dev/work` include an untracked, machine-local identity.

```bash
mkdir -p ~/dev/work ~/dev/personal
git config --file ~/.gitconfig-work-local user.name "<work display name>"
git config --file ~/.gitconfig-work-local user.email "<work email>"

git -C ~/dev/repos/dotfiles config user.email
git config --includes --file ~/.gitconfig-work user.email
```

The first verification should print the personal address and the second the
new work address. Put employer repositories below `~/dev/work`; do not commit
`~/.gitconfig-work-local`.

## 2. Finish terminal and macOS setup

1. Confirm iTerm2 uses **MesloLGS NF** so prompt glyphs render.
2. Open Thaw, grant Screen Recording, and enable launch at login.
3. Paste the Alfred Powerpack license. Disable Spotlight's Command-Space
   shortcut first if Alfred should use it.
4. Sign in to Apple ID, GitHub (`gh auth login`), Spotify, Claude Desktop, and
   Docker Desktop / Docker Hub. Accept Docker's first-run terms.
5. Quit iTerm2 and run `~/dev/repos/dotfiles/steps/35-iterm2.sh` from another
   terminal. Reopen it and confirm new tabs start in tmux.
6. Make zsh the default shell if needed: `chsh -s /bin/zsh`.
7. Restart the shell (or run `source ~/.zshrc`).

## 3. Configure Engineering System

The tooling checkout is installed at `~/dev/repos/engineering-system`; its
private data remains outside Git at
`~/.local/share/engineering-system-data`. Set `worklogPath` to Worklog's data
directory, not its checkout, and explicitly register only repositories that
should participate in the knowledge system.

```bash
$EDITOR ~/dev/repos/engineering-system/config.local.json
# worklogPath: /Users/<username>/.local/share/worklog-data

~/dev/repos/engineering-system/scripts/setup.sh --no-settings
~/dev/repos/dotfiles/steps/80-claude-settings.sh
~/dev/repos/engineering-system/scripts/doctor.sh
```

Use an absolute path containing the actual account name in JSON; `~` is not
expanded there. Later, `register-repo.sh` preserves Dotfiles' delegated Claude
settings ownership and does not take it back.

## 4. Run sanity checks

```bash
node --version && go version && python3 --version && uv --version && tsx --version
mise current
which node go python3
git -C ~/dev/repos/worklog status
~/dev/repos/dotfiles/scripts/doctor.sh
```

`mise current` should list Node, Python, and Go; all three executable paths
should be under `~/.local/share/mise/installs`; and Worklog's `git status` must
succeed because it is an ordinary checkout.

Key repeat, trackpad preferences, and Finder's hidden-file setting remain
manual because their automation is brittle across macOS releases.
