# Historical implementation brief: `~/dev/repos/dotfiles`

> This records the reasoning behind the initial implementation. It is not an
> operational runbook and some examples describe designs that have since been
> replaced. `README.md`, the numbered scripts, and
> `docs/post-bootstrap-checklist.md` are authoritative when they disagree with
> this history.

## Goal

One git repo that takes a fresh macOS machine to a working dev environment via a single
`./bootstrap.sh`. It reproduces the **behaviour** of the owner's current machine — not its
accumulated cruft. Target stack: **Go, Python, Node**. No Java.

## Locked decisions (do not revisit)

| Decision | Choice | Reason |
|---|---|---|
| Runtimes (Node, Python, Go) | **mise only** — no `brew "node"`, no `brew "go"`, no fnm, no nvm | One polyglot manager for all three. Rust binary, near-zero shell-startup cost, reads `.nvmrc` / `.tool-versions` / `mise.toml`. Replaced the earlier fnm+brew-go split after a trial on the current machine. |
| Python tooling | **mise owns the interpreter, `uv` owns projects** — no `python@3.13`, no poetry | uv is kept for venvs, lockfiles and `uvx`; the interpreter itself comes from mise so `python3` is never Apple's 3.9. |
| Terraform | **hashicorp/tap/terraform** | Current releases; homebrew-core is frozen at 1.5.7 |
| worklog layout | **Checkout at `~/dev/repos/worklog`; data at `~/.local/share/worklog-data`** | Keeps public tooling reproducible while private content stays outside Git. |
| Prompt | **Starship** (`brew "starship"`, `eval "$(starship init zsh)"`) | Actively maintained, cross-shell, single TOML config. Replaced powerlevel10k (which is on life-support) after a trial. p10k is fully removed: no formula, no `.p10k.zsh`, no source lines. |
| Interactive zsh | **oh-my-zsh kept for completion + git aliases**, `ZSH_THEME=""`, plus brew `zsh-autosuggestions` + `zsh-syntax-highlighting` | Starship is prompt-only; it does nothing for completion/suggestions. omz stays for `compinit` wiring and the `git` plugin's aliases, with the theme neutralised since Starship owns the prompt. |
| claude-code | **Homebrew cask** (`claude-code`) | Already distributed this way; no curl installer needed |
| Java | **removed entirely** | New job is Go/Python/Node only |
| git identity | **`includeIf gitdir:` split** — tracked personal identity for `~/dev/repos` and `~/dev/personal`; untracked work identity below `~/dev/work` | Unknown employer identity stays local and public tooling never inherits it. |

## Environment facts (verified on the current machine)

- Apple Silicon; Homebrew at `/opt/homebrew`. macOS **26.5.1**.
- **The current machine has already been migrated to mise** (see "Live-machine migration" below).
  `node`, `python3` and `go` all resolve to `~/.local/share/mise/installs/...`; brew's `node`,
  `go` and `mongosh` have been uninstalled.
- `/usr/bin/python3` is still Apple's **deprecated system Python 3.9** (shipped via
  CommandLineTools), but it is no longer first on PATH — mise's 3.13 shadows it. It still matters
  for one thing: worklog's installer hard-requires a `python3`, see Phase 7.
- `~/.oh-my-zsh/custom/{plugins,themes}` contain only the `example` stubs — nothing to clone.
- `~/.config/nvim` uses lazy.nvim (`lazy-lock.json` present).
- `~/.config/iterm2/AppSupport` is a symlink into `~/Library/Application Support/iTerm2` —
  **not** a portable settings export.
- `.zprofile` is one line: `eval "$(/opt/homebrew/bin/brew shellenv)"`.
- `.gitconfig` identity is currently the personal address `jakob.filip.lindberg@gmail.com`.

### Live-machine migration (already done, 2026-07-27)

The current machine was migrated ahead of the repo so the plan describes a setup that has actually
been run, not a hypothetical one. What changed:

- Installed `mise`.
- Menu bar manager: installed Ice (`jordanbaird-ice`), found it **crashes on macOS 26** — six
  `EXC_BREAKPOINT` crash reports in four minutes, trapping in a debounced Combine handler. It had
  registered itself as a login item, so it was crash-looping in the background. Uninstalled it and
  installed **Thaw** (`thaw` 1.2.0), the maintained fork, which runs clean: no crash reports, XPC
  helper up, registered with launchd. Thaw still needs its Screen Recording grant and
  launch-at-login enabling by hand (Phase 11 step 3).
- Wrote `~/.config/mise/config.toml` with `node = "lts"`, `python = "3.13"`, `go = "1.26"`;
  `mise install` resolved these to node 24.18.0, python 3.13.14, go 1.26.5.
- Added `eval "$(mise activate zsh)"` to `~/.zshrc`, **after** the `PATH` export.
- Removed the `certifi` / `SSL_CERT_FILE` / `REQUESTS_CA_BUNDLE` block — see the divergence note
  in Phase 3 for why it became actively wrong once mise owned `python3`.
- Uninstalled brew `go`, `mongosh`, and then `node` (removing `mongosh` promoted `node` from a
  dependency to an unused leaf, so `brew autoremove` did **not** catch it — it needed an explicit
  `brew uninstall node`).
- Zapped Bartender (`brew uninstall --zap --cask bartender`): app, cask registration, launchctl
  service, user preferences and its HAL audio plugin are all gone. The zap reported a `sudo`
  failure partway through on the system-level plugin path, but the removal did complete —
  verify with `brew list --cask | grep bartender` before assuming otherwise. Note the zap also
  deleted Bartender's stored license activation; the key itself is recoverable from the vendor
  account if you ever want to go back.

`JAVA_HOME` was deliberately left in place on this machine — there is still a JDK (openjdk 25) and
Java work here. The fresh machine drops it.

---

## Repository layout

```
~/dev/repos/dotfiles/
├── README.md              # setup overview and architecture
├── bootstrap.sh           # orchestrator: runs steps/ in order, prints checklist
├── Brewfile
├── repos.txt              # generic clones, tab-separated: url<TAB>target
├── justfile               # lint / fmt / test / check / doctor targets
├── .editorconfig
├── ruff.toml              # pinned Python lint/format policy
├── .gitignore             # local and generated files
├── steps/
│   ├── 10-homebrew.sh
│   ├── 20-packages.sh
│   ├── 30-dotfiles.sh
│   ├── 40-omz.sh
│   ├── 50-repos.sh
│   ├── 60-runtimes.sh      # mise install (node + python + go) + global tsx
│   ├── 70-worklog.sh
│   ├── 75-engineering-system.sh
│   └── 80-claude-settings.sh
├── scripts/
│   ├── doctor.sh           # read-only repository + machine health
│   ├── reconcile-claude-settings.py
│   └── sanitize-iterm2-plist.py
├── home/                  # symlinked into $HOME
│   ├── .zshrc
│   ├── .zprofile
│   ├── .gitconfig         # location-based identity dispatcher
│   ├── .gitconfig-personal
│   └── .gitconfig-work    # includes untracked ~/.gitconfig-work-local

├── config/                # symlinked into ~/.config/<name>
│   ├── nvim/
│   ├── mise/              # config.toml — global runtime versions
│   └── starship.toml      # symlinked to ~/.config/starship.toml
└── iterm2/                # iTerm2 settings export (populated manually by the human)
```

Two trees (`home/`, `config/`) because they have different link rules — dotfile-into-`$HOME`
vs directory-into-`~/.config`. This keeps `30-dotfiles.sh` as two small loops rather than a
special-cased list.

---

## Phase 1 — Repo skeleton

`~/dev/repos/dotfiles` already exists and is empty.

1. `git init -b main`
2. Write `.gitignore` containing `.DS_Store` and `*.local`.
3. `mkdir -p steps home config iterm2`

## Phase 2 — Capture existing config

Copy in, **verify**, *then* replace originals with symlinks. Never `rm` an original before its
`diff` passes.

```bash
cp ~/.zshrc ~/.zprofile ~/.gitconfig home/
cp -R ~/.config/nvim config/nvim
cp ~/.config/starship.toml config/starship.toml
cp -R ~/.config/mise config/mise
diff -r ~/.config/nvim config/nvim     # must be clean before proceeding
```

- `config/nvim/lazy-lock.json` — **commit it**. It pins plugin versions reproducibly.
- `config/starship.toml` — the owner's tuned prompt config (directory / git / go / python / aws
  / kubernetes modules, right-aligned clock). Commit as-is. This replaces the old `.p10k.zsh`.
- `config/mise/config.toml` — global runtime versions (`node = "lts"`, `python = "3.13"`,
  `go = "1.26"`). Commit it. Per-project pins in a repo's own `mise.toml` / `.tool-versions` /
  `.nvmrc` override these, which is the point of using mise.
- `home/.zprofile` is the single `brew shellenv` line above. Correct as-is.
- `home/.gitconfig` — **rewritten for the identity split**, see below. Do NOT copy it verbatim.

### `home/.gitconfig` — work/personal identity split (`includeIf gitdir:`)

The final design has no global `[user]` block. The dispatcher includes the
tracked `~/.gitconfig-personal` for repositories below `~/dev/repos/` and
`~/dev/personal/`. Repositories below `~/dev/work/` include
`~/.gitconfig-work`, which in turn includes the untracked,
machine-local `~/.gitconfig-work-local`.

This keeps the future employer identity out of the public Dotfiles history and
prevents public tooling commits from accidentally inheriting a work address.
Git chooses by the repository's on-disk location, so employer repositories
belong under `~/dev/work/`. The operational creation and verification commands
live only in `docs/post-bootstrap-checklist.md`.

> `.zshrc` is NOT copied verbatim — it is rewritten in Phase 3. Copy it into `home/` first only
> so you have the original to diff against, then overwrite `home/.zshrc` with the version below.

## Phase 3 — Rewrite `home/.zshrc`

The captured file is ~120 lines: ~100 are stock oh-my-zsh template comments and 4 are actively
harmful on a fresh machine. Replace the entire file with exactly this:

```bash
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

# Worklog is installed after this file is linked, so source it conditionally.
if [ -f "$HOME/dev/worklog/config/shell/aliases.sh" ]; then
  source "$HOME/dev/worklog/config/shell/aliases.sh"
fi
```

> **Source-order rules that matter here:** `zsh-syntax-highlighting` must come **after**
> `zsh-autosuggestions` and after any other line editing setup, or highlighting silently
> breaks. `starship init` goes near the end. The old p10k "instant prompt" block at the very
> top of the file is **gone** — it was p10k-specific and has no Starship equivalent; do not
> re-add it.

### What was removed, and why (do not add these back)

| Removed line | Why |
|---|---|
| `export JAVA_HOME=$(/usr/libexec/java_home)` | No Java. On a machine without a JDK this command errors to stderr on every shell start. |
| `export SSL_CERT_FILE=$(python3 -c "import certifi; ...")` | Resolves against Apple's deprecated system Python 3.9 and reads a `pip install --user` artifact under `~/Library/Python/3.9/`. On a fresh machine the import fails, the `$( )` yields empty, and you export **`SSL_CERT_FILE=""`** — worse than unset: some TLS stacks honour it, find no CA bundle, and break HTTPS confusingly. |
| `export REQUESTS_CA_BUNDLE=$(python3 -c "import certifi; ...")` | Same, and spawns a second Python interpreter per shell start. |
| ~100 lines of omz template comments | Recoverable from omz's repo; a 30-line file is one you'll actually read. |
| worklog-managed alias block (`# >>> worklog aliases >>> ... <<<`) | Dotfiles owns one stable source line instead, and invokes Worklog with `--no-aliases`, so setup never dirties this checkout. |

`ZSH_THEME=""` rather than `"robbyrussell"`: Starship owns the prompt, so any omz theme would be
inert. Empty is the honest description. oh-my-zsh itself is kept — but only for `compinit`
completion wiring and the `git` plugin's aliases (`gst`, `gco`, …); Starship is prompt-only and
does nothing for completion or suggestions, which is why the two `zsh-*` plugins are sourced too.

If a specific tool later needs a CA bundle, set it for **that tool**, not globally in the shell.

### Added vs. the current machine (do not drop these)

- `export EDITOR="nvim"` / `export VISUAL="nvim"` — the current machine left these unset, so git,
  `kubectl edit`, etc. fell back to vi. neovim is installed by the Brewfile; set it explicitly.
- The Homebrew-`fpath` block before `compinit` — gives tab-completion for brew-installed tools
  (`gh`, `docker`, …). Must run **before** `source "$ZSH/oh-my-zsh.sh"` (which calls `compinit`).

### Live-machine vs. fresh-machine divergence (intentional — do not "fix")

After the mise migration the two files are nearly identical. The **only** remaining intentional
difference is `JAVA_HOME`: the current machine still has a JDK (openjdk 25) and does Java work, so
the guarded `JAVA_HOME` block stays there. The **fresh** work machine drops it entirely per the
removal table above, because the new job is Java-free. Do not reconcile that one difference.

The `certifi` block is now gone from **both** files. It was removed from the live machine during
the mise migration: once mise's Python 3.13 became the default `python3`, the block started
resolving `certifi` out of the stale `~/Library/Python/3.9/` user site-packages directory and
exporting a 3.9-era CA bundle to a 3.13 interpreter. That is the same class of bug the removal
table describes, so it was fixed in place rather than left as a "live-machine only" quirk.

## Phase 4 — `Brewfile`

```ruby
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
```

### Package notes (important — several are traps)

- **No `curl`** — macOS ships it. Brew's is keg-only and needs an explicit PATH entry to shadow
  the system one; not worth it unless an openssl-linked build is required.
- **`docker` + `docker compose` both ship inside the `docker-desktop` cask.** Do NOT also
  `brew install docker` — that standalone CLI conflicts. (The cask was renamed `docker` →
  `docker-desktop`.)
- **`terraform`** via HashiCorp's tap = current releases. Homebrew-core's `terraform` is frozen
  at 1.5.7.
- **`mise`** needs the one-line `.zshrc` wiring in Phase 3 (already included), and it must come
  **after** the `PATH` export so its shims win. Like fnm it's a Rust binary, so no
  multi-hundred-ms shell-startup penalty.
- **No `brew "node"`, no `brew "go"`** — deliberate; see Phase 5. Installing either alongside mise
  gives you a second toolchain that shadows or is shadowed depending on PATH order, which is the
  exact "wrong version" confusion mise exists to prevent. `mongosh` (excluded here) was the only
  reason brew node existed on the current machine.
- **`uv` is still installed** and is not redundant with mise: mise provides the *interpreter*, uv
  provides venvs, lockfiles and `uvx`. Let mise own the Python version — do not also use
  `uv python install` to pin interpreters, or you get two managers racing for `python3`.
- **`thaw`** is the cask name; the app is "Thaw". Like Bartender it needs a Screen Recording grant
  on first run (see Phase 11). Thaw is an actively maintained **fork of Ice**, which stalled and
  crashes on macOS 26 — do NOT use the `jordanbaird-ice` cask, see the note below.
- **Menu bar manager history (don't re-litigate):** Bartender (paid, contentious since its 2024
  acquisition) → Ice (free/OSS, but unmaintained and **crashes on macOS 26**) → Thaw. Ice 0.11.12
  was trialled on the current machine and died repeatedly with `EXC_BREAKPOINT` in a debounced
  Combine handler, six crash reports in four minutes. Thaw ran clean with zero crash reports.
  The Homebrew cask is `thaw` (1.2.0); upstream is further ahead on 2.0.0-rc with macOS 27 preview
  builds, and a `thaw@beta` cask exists if the stable one lags a future macOS release.
- **`ast-grep`** installs binaries `ast-grep` and `sg`; `sg` can collide with a system binary of
  that name — prefer invoking `ast-grep`.
- **`tmux` and iTerm2 are unrelated** — emulator vs multiplexer; both wanted.

### Deliberately excluded from the current machine

`ffmpeg`, `maven`, `mongosh`, `poetry`, `figma`, `firefox`, `transmission`,
`visual-studio-code`. Add back individually if the new job needs them. Excluding `maven` and
`mongosh` is consistent with dropping Java.

## Phase 5 — Runtime strategy (Node, Python, Go)

**mise owns all three runtimes. Homebrew installs none of them.**

mise is a Rust binary (the former `rtx`, an asdf clone) that manages multiple language runtimes
from one config file. It installs shims rather than running a shell function on every prompt, so
like fnm it has effectively zero shell-startup cost. It reads `.nvmrc`, `.node-version`,
`.tool-versions` and `mise.toml`, so per-project pinning works with whatever convention a repo
already uses.

Why one manager instead of fnm + brew-go: a single tool, a single config file, and per-project
pinning for Go as well as Node. Go's `toolchain` directive in `go.mod` covers a lot of this on its
own, but having `go` come from the same place as `node` and `python` means one upgrade path and no
"which go is this" ambiguity.

Global versions live in `config/mise/config.toml` (symlinked to `~/.config/mise/config.toml`):

```toml
[tools]
node = "lts"
python = "3.13"
go = "1.26"
```

Conflicts avoided: do NOT also `brew install node` or `brew install go`. mise puts the active
version first on PATH; a brew-installed runtime would be dead weight that still upgrades on every
`brew upgrade` and causes "wrong version" confusion. This is the same reasoning that applied to
fnm, extended to Go.

**Python specifically:** mise provides the interpreter, `uv` provides project tooling (venvs,
lockfiles, `uvx`). They coexist cleanly as long as only one of them owns the interpreter version —
so do not use `uv python install` to pin interpreters on top of mise.

`steps/60-runtimes.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Versions come from ~/.config/mise/config.toml, symlinked by 30-dotfiles.sh.
# That symlink must already exist, so keep step 30 before this one.
mise install
mise reshim

# tsx as an npm global under the mise-managed default node (see caveat below).
mise exec node -- npm install -g tsx
mise reshim
```

> Note: `mise` must be on PATH when this runs — i.e. `20-packages.sh` (which installs it) must
> have run first, and Homebrew's shellenv must be active in the bootstrap shell. `10-homebrew.sh`
> already evals shellenv; keep the step order. `mise install` with no arguments reads the config
> file, so there is no version alias to get wrong here.

**`tsx` caveat (document in README):** `tsx` is an npm global — it belongs to whichever node
version was active at install time and disappears after switching to a different mise-managed
version. This plan installs it under the global default and accepts that; `mise reshim` is what
makes it visible on PATH afterwards. Alternatives, ascending correctness: `npx tsx` per call; or a
per-project devDependency (the right answer for real projects). This is inherent to npm globals,
not to the version manager.

**Startup cost:** `eval "$(mise activate zsh)"` is near-instant, so there is no shell-startup
penalty to apologise for and no lazy-loading needed.

## Phase 6 — Step scripts

Every script starts with `#!/usr/bin/env bash` and `set -euo pipefail`, is idempotent, and is
independently runnable. `$REPO` = the dotfiles repo root (derive from the script's own path).

| Script | Behaviour | Idempotency guard |
|---|---|---|
| `10-homebrew.sh` | Install Homebrew if missing; then `eval "$(/opt/homebrew/bin/brew shellenv)"` | `command -v brew` |
| `20-packages.sh` | `brew bundle --file="$REPO/Brewfile"` | brew bundle is natively idempotent |
| `30-dotfiles.sh` | Symlink `home/*` → `$HOME/`, `config/*` → `$HOME/.config/` | Back up any existing **real** file to `*.bak-<timestamp>` before linking; skip if already the correct symlink |
| `40-omz.sh` | Install oh-my-zsh unattended (see trap below) | `[ -d ~/.oh-my-zsh ]` |
| `50-repos.sh` | `mkdir -p ~/dev/{repos,go}`; clone each line of `repos.txt` if target missing | `[ -d "$target" ]` per repo |
| `60-runtimes.sh` | `mise install` (node + python + go) + global tsx (Phase 5) | mise's own idempotency (`mise install` is a no-op if the versions are present) |
| `70-worklog.sh` | Clone/update an ordinary checkout and run setup without shared-settings ownership | checkout existence plus setup idempotence |
| `75-engineering-system.sh` | Run Engineering System setup with externally managed settings when its repository is present | setup is idempotent; missing repository is reported and skipped |
| `80-claude-settings.sh` | Central Claude settings reconciliation for Worklog and optional Engineering System | owned state in `~/.local/state/dotfiles/claude-settings.json` |

### The oh-my-zsh ordering trap

oh-my-zsh's installer overwrites `~/.zshrc` and launches a new shell. Suppress both:

```bash
KEEP_ZSHRC=yes RUNZSH=no CHSH=no \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

`KEEP_ZSHRC=yes` is what makes it safe to run step 40 **after** step 30 — without it the
installer clobbers the symlink you just created. `RUNZSH=no` keeps `bootstrap.sh` in control of
its shell. No `$ZSH_CUSTOM` clones are needed: `plugins=(git)` is bundled with omz, and
`zsh-autosuggestions` / `zsh-syntax-highlighting` are brew formulae sourced directly from
`/opt/homebrew/share/...` (not installed as omz custom plugins).

### `bootstrap.sh`

Sources the step scripts in numeric order, stopping on first failure (`set -euo pipefail`). Ends
by printing `docs/post-bootstrap-checklist.md` verbatim.

## Phase 7 — Worklog and Engineering System

Worklog is an ordinary checkout at `~/dev/repos/worklog`; its private data is
at `~/.local/share/worklog-data`. Step 70 clones the checkout when absent and
runs its setup with `--no-settings --no-aliases`, leaving aliases and shared
Claude settings under Dotfiles ownership.

Engineering System is a public tooling checkout at
`~/dev/repos/engineering-system`; its private data is external at
`~/.local/share/engineering-system-data`. Step 75 runs setup with
`--no-settings`. Step 80 is the sole settings reconciler: it owns the
directory grants, Worklog cadence hook, and Engineering System inbox-depth
hook, recording only its entries in
`~/.local/state/dotfiles/claude-settings.json`.

Both systems resolve data directories from their environment override, then
gitignored local config, then their XDG default. Engineering System's
`worklogPath` must be the Worklog data directory containing
`commitments.md`, never the Worklog checkout.

## Phase 8 — iTerm2

`scripts/iterm2-export.sh` snapshots the live preferences into `iterm2/` as XML, and
`steps/35-iterm2.sh` points a new machine back at that folder. Run the export on the
current machine and commit the result.

> **Export on the CURRENT machine before leaving it** — otherwise font, profile, and colour
> settings are lost. `~/.config/iterm2/AppSupport` is only a symlink into
> `~/Library/Application Support/iTerm2`, not a portable export.

Both the export and the restore are affected by iTerm2 holding its preferences in memory and
rewriting them on quit. `steps/35-iterm2.sh` therefore refuses to run while iTerm2 is open,
because a running instance would silently revert the change on exit; quit iTerm2 and rerun the
step. Once the step has run, iTerm2 reads and writes the checkout directly, so later settings
changes show up as diffs in `iterm2/` and the export script is no longer needed.

## Phase 9 — README

The README covers two things the numbered flow doesn't:

**Pre-bootstrap prerequisites** (must happen before `./bootstrap.sh` can run at all):
- `xcode-select --install` (must precede Homebrew — provides git + compilers).
- SSH key: `ssh-keygen -t ed25519 -C "<email associated with GitHub>"` → `pbcopy < ~/.ssh/id_ed25519.pub` →
  add to GitHub → `ssh -T git@github.com`. Needed to clone private repos.

**Post-bootstrap steps** — do NOT re-list them here. The authoritative copy is
`docs/post-bootstrap-checklist.md`, which `bootstrap.sh` prints on completion.
The README points to that file and keeps architecture caveats near the code:
- The tsx-as-npm-global caveat (Phase 5).
- Worklog is an ordinary checkout whose private data is external.

Do not duplicate the operational checklist in this historical brief.

## Phase 10 — Verification

Real verification needs a clean machine. In ascending cost:

1. **`just check`** — ShellCheck, shfmt, pinned Ruff checks, settings tests,
   sandboxed bootstrap tests, and the repository-only doctor. `just fmt`
   applies the shared shell and Python formatting policy.
2. **Re-run `./bootstrap.sh` on the current machine — it must be a complete no-op.** This is the
   idempotency test and is nearly free. Any step doing work on the second run has a missing guard.
3. **Throwaway macOS user account**, run bootstrap there. Catches the "assumes something already
   in `$HOME`" class of bug that (2) structurally cannot.
4. **Fresh macOS VM (Tart/UTM)** — the only true test; worth it if the repo will be reused.

Honest caveat to surface to the human: until (3) or (4) runs, this is untested code.

## Phase 11 — Post-bootstrap handoff

The operational manual tail lives in `docs/post-bootstrap-checklist.md`.
`bootstrap.sh` prints that file verbatim and fails if it is missing or empty.
Do not duplicate its identity, GUI, Engineering System, or verification
instructions here; one canonical checklist is what prevents path and
architecture drift.

---

## Fresh-machine flow (what the human runs later)

```
xcode-select --install
ssh-keygen + add public key to GitHub
git clone <dotfiles remote> ~/dev/repos/dotfiles
cd ~/dev/repos/dotfiles && ./bootstrap.sh
   → 10 homebrew → 20 packages → 30 dotfiles → 40 omz
   → 50 repos → 60 node → 70 worklog → 75 Engineering System → 80 Claude settings
   → bootstrap prints docs/post-bootstrap-checklist.md
work through that checklist (local work identity, configuration, sign-ins, verification)
```

## Open items (raise with the human; do not silently decide)

- **Excluded packages** — confirm `ffmpeg`, `mongosh`, etc. genuinely aren't needed before first
  real use.
- **Worklog layout migration** — resolved: the ordinary checkout is canonical
  and private data is external.

## Execution guardrails (for the agent)

- Terminal deliverable = repo files written and committed. Do **not** run `bootstrap.sh` against a
  real machine unless separately asked.
- Before replacing any live `$HOME` file with a symlink: copy → `diff` → only then link, backing
  up any real file to `*.bak-<timestamp>`.
- Avoid destructive commands in bootstrap and keep temporary work scoped to
  validated, per-run directories.
- Keep each step script small, single-purpose, `set -euo pipefail`, and independently re-runnable.
- If reality diverges from the "Environment facts" above (e.g. paths differ), stop and report
  rather than guessing.
