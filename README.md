# dotfiles

One repository for taking a fresh Apple Silicon Mac to a Go, Python, and Node
development environment. Homebrew installs system tools and applications;
[mise](https://mise.jdx.dev/) owns all three language runtimes; and
[uv](https://docs.astral.sh/uv/) owns Python project environments and tooling.

## Before bootstrapping

Install Apple's command-line tools first. They provide Git and the compilers
Homebrew needs:

```bash
xcode-select --install
```

Create an SSH key for the new machine, add its public key to GitHub, and verify
GitHub authentication before cloning private repositories:

```bash
ssh-keygen -t ed25519 -C "<email associated with GitHub>"
pbcopy < ~/.ssh/id_ed25519.pub
ssh -T git@github.com
```

Then clone this repository at its expected path and run the orchestrator:

```bash
git clone <dotfiles remote> ~/dev/repos/dotfiles
cd ~/dev/repos/dotfiles
./bootstrap.sh
```

The bootstrap installs Homebrew and the `Brewfile`, backs up existing config
before linking this repository, installs oh-my-zsh, clones repositories listed
in `repos.txt`, installs the mise runtimes and `tsx`, and installs worklog using
its ordinary checkout and external data directory. Dotfiles then centrally
reconciles the Claude settings and hooks used by Worklog and Engineering
System. Every numbered step is independently runnable and intended to be
idempotent.

After the script finishes, follow the numbered manual checklist it prints.
[That checklist](docs/post-bootstrap-checklist.md) is authoritative for the
local work Git identity, permissions, licenses, sign-ins, terminal settings,
Engineering System configuration, and verification.

## Before leaving the old machine

iTerm2's `~/.config/iterm2/AppSupport` link is not a portable settings export.
Run `scripts/iterm2-export.sh` to snapshot the live preferences into `iterm2/`,
and commit the result before moving to the new machine. The export is XML rather
than iTerm2's native binary format, so settings changes show up as readable
diffs. The export script sanitizes the current macOS home path before writing,
so an unknown account username cannot leak into the committed profile.

The snapshot is the whole preference domain, so it carries the profile as a
unit — including the custom command `/bin/zsh -lc 'exec tmux new-session'` that
starts every new tab in tmux, and automatic shell integration loading.

On the new machine, `steps/35-iterm2.sh` points iTerm2 back at the checkout.
iTerm2 keeps its preferences in memory and rewrites them on quit, so the step
refuses to run while iTerm2 is open — otherwise the change is silently reverted
the next time iTerm2 exits. Quit iTerm2, run the step from another terminal, and
reopen it. From then on iTerm2 reads and writes `iterm2/` directly, so changes
made through its own UI land in the checkout and `iterm2-export.sh` is no longer
needed.

## Runtime notes

Do not install Node or Go through Homebrew, and do not use `uv python install`
to pin the global interpreter. mise is the single runtime manager; project
files such as `mise.toml`, `.tool-versions`, and `.nvmrc` override the global
defaults in `config/mise/config.toml`.

`tsx` is installed as an npm global under the active default Node version.
Changing mise's Node version can therefore make that global disappear. Use
`npx tsx` for one-off calls, or install `tsx` as a project dev dependency for
real projects.

## worklog and Engineering System data

Both are ordinary checkouts under `~/dev/repos`. Their private content lives
outside the repositories, in separate data directories:

| Repository | Checkout | Data |
| --- | --- | --- |
| worklog | `~/dev/repos/worklog` | `~/.local/share/worklog-data` |
| Engineering System | `~/dev/repos/engineering-system` | `~/.local/share/engineering-system-data` |

Each resolves its data directory from `$WORKLOG_DATA_DIR` / `$ES_DATA_DIR`,
then `dataDir` in a gitignored `config.local.json`, then the XDG default above.

worklog stays out of `repos.txt` because it needs `scripts/setup.sh` run after
cloning; `steps/70-worklog.sh` does both. Use
`~/dev/repos/worklog/scripts/doctor.sh` to verify it.

Engineering System's `config.local.json` sets `worklogPath` to worklog's **data
directory** (the one holding `commitments.md`), not its checkout.

## Claude settings ownership

Dotfiles is the central owner of the Claude directory grants, Worklog cadence
hook, and Engineering System inbox-depth hook for this machine. It invokes
Worklog with `--no-settings --no-aliases`; the aliases are sourced directly by
`home/.zshrc`. If
`~/dev/repos/engineering-system` exists, step 75 invokes its setup with
`--no-settings`. Step 80 then includes its configured paths in the same central
reconciliation.

Step 80 passes worklog's **checkout** as `--worklog`, because that both grants
the directory and locates the cadence hook at `scripts/cadence.sh`. It also
adds Engineering System's `scripts/inbox-depth.sh` hook when installed.
Worklog's data directory is granted separately, via the path Engineering
System reports.

The ownership manifest lives outside every checkout at
`~/.local/state/dotfiles/claude-settings.json`. This keeps install order from
letting one package remove settings another package still needs.

## Development

The validation commands do not run bootstrap:

```bash
just lint
just fmt
just check
just doctor
```

`just lint` runs ShellCheck, verifies shfmt formatting, and checks the Python
utilities with the Ruff version pinned in `justfile`. `just test` exercises the
Claude settings reconciler, iTerm2 portability, and bootstrap steps in
temporary directories.
`just doctor` is different: it inspects the real machine without changing it,
including Homebrew, links, mise runtimes, Worklog, Engineering System, and
central Claude settings. A true bootstrap test still requires a throwaway macOS
user or a fresh VM.

Packages intentionally excluded from the current machine include `ffmpeg`,
`maven`, `mongosh`, `poetry`, Figma, Firefox, Transmission, and VS Code. Add
them individually only if the new job needs them.
