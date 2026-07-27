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
ssh-keygen -t ed25519 -C "<work email>"
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
its mirror layout. Every numbered step is independently runnable and intended
to be idempotent.

After the script finishes, follow the numbered manual checklist it prints. That
checklist is authoritative for the remaining Git identity, permissions,
licenses, sign-ins, terminal settings, and verification.

## Before leaving the old machine

iTerm2's `~/.config/iterm2/AppSupport` link is not a portable settings export.
In iTerm2, open Settings → General → Settings, enable “Load settings from a
custom folder or URL,” choose `~/dev/repos/dotfiles/iterm2`, and save the
settings there. Commit the export before moving to the new machine.

## Runtime notes

Do not install Node or Go through Homebrew, and do not use `uv python install`
to pin the global interpreter. mise is the single runtime manager; project
files such as `mise.toml`, `.tool-versions`, and `.nvmrc` override the global
defaults in `config/mise/config.toml`.

`tsx` is installed as an npm global under the active default Node version.
Changing mise's Node version can therefore make that global disappear. Use
`npx tsx` for one-off calls, or install `tsx` as a project dev dependency for
real projects.

## worklog's mirror layout

worklog lives at `~/dev/worklog`, while its Git data lives separately at
`~/.local/share/worklog.git`. The work tree intentionally contains no `.git`.
Consequently, this command failing with “not a git repository” is the success
condition:

```bash
git -C ~/dev/worklog status
```

Use `~/dev/worklog/scripts/doctor.sh` to verify the mirror. Do not move worklog
into `~/dev/repos`, and do not add it to `repos.txt`.

## Development

The validation commands do not run bootstrap:

```bash
just lint
just fmt
just check
```

`just lint` runs ShellCheck and verifies shfmt formatting. A true bootstrap
test still requires a throwaway macOS user or a fresh VM; until then, the setup
scripts have not been tested on a clean machine.

Packages intentionally excluded from the current machine include `ffmpeg`,
`maven`, `mongosh`, `poetry`, Figma, Firefox, Transmission, and VS Code. Add
them individually only if the new job needs them.
