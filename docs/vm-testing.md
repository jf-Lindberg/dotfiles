# Testing bootstrap on a fresh machine

`tests/test-bootstrap-sandbox.sh` covers the steps that derive their targets
from `$HOME` (30, 50, 70, 75, 80). It cannot cover steps 10, 20, 40, and 60:
Homebrew, oh-my-zsh, and the mise runtimes install to machine-global locations,
and `steps/10-homebrew.sh` asserts `/opt/homebrew/bin/brew` outright. Those
steps need a real fresh macOS install.

This is a supervised session, not an unattended one. `20-packages.sh` installs
GUI casks (`claude`, `docker-desktop`, `iterm2`, `alfred`, `spotify`) that
prompt for an administrator password, and macOS grants Screen Recording and
similar permissions only through dialogs a script cannot answer. Budget about
40 minutes and stay at the keyboard.

## What only a VM can tell you

- Homebrew installs cleanly on a machine that has never seen it.
- Every formula and cask in the `Brewfile` still resolves and installs.
- `mise install` provisions Go, Python, and Node from the linked
  `config/mise/config.toml`, and `tsx` lands under the default Node.
- The real `70-worklog.sh` clone from GitHub creates an ordinary checkout at
  `~/dev/repos/worklog`, runs setup without claiming shared settings, and uses
  the external Worklog data directory.
- The ordering assumption holds end to end — step 30 links the mise config
  before step 60 reads it.
- `docs/post-bootstrap-checklist.md` prints verbatim, and its manual steps are
  followed by a human.

## Setup

Tart is the lightest option on Apple Silicon. Expect a 20–40 GB image pull.

```bash
brew install cirruslabs/cli/tart
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest bootstrap-test
tart run bootstrap-test
```

Take the clean snapshot **before** running anything, so each attempt starts
from the same state:

```bash
tart stop bootstrap-test
tart clone bootstrap-test bootstrap-test-clean   # the snapshot
```

Restore between attempts:

```bash
tart delete bootstrap-test
tart clone bootstrap-test-clean bootstrap-test
```

## The run

Inside the VM, follow `README.md` exactly as a new machine would — do not take
shortcuts, since the point is to test the documented path:

```bash
xcode-select --install
ssh-keygen -t ed25519 -C "<work email>"
# add the public key to GitHub, then:
ssh -T git@github.com
git clone <dotfiles remote> ~/dev/repos/dotfiles
cd ~/dev/repos/dotfiles
./bootstrap.sh
```

## What to watch for

- **Step 10** — Homebrew's installer asks for a password and prints its own
  PATH advice. The step's `brew shellenv` should make later steps work without
  opening a new shell.
- **Step 20** — the slowest phase by far. Cask failures are the most likely
  breakage: renamed casks, ones needing Rosetta, or ones that changed their
  install prompt.
- **Step 60** — fails if `~/.config/mise/config.toml` is missing, which means
  step 30 did not link it. This is the ordering dependency.
- **Step 70** — needs GitHub access. On a VM without your SSH key it falls back
  to HTTPS; confirm which path it took.
- **Step 80** — runs the real `doctor.sh`. It only warns on failure and does
  not stop the bootstrap, so read its output rather than trusting the exit code.
- **The tail** — the dedicated post-bootstrap checklist must actually print.
  `bootstrap.sh` exits non-zero if the file is missing or empty.

## Second run

Re-run `./bootstrap.sh` in the same VM without restoring the snapshot. The
sandbox test already proves steps 30–80 are idempotent, so this is confirming
the machine-global steps: Homebrew should report everything installed, `brew
bundle` should be a no-op, oh-my-zsh should skip, and no `.bak-*` files should
appear.

## Cleanup

VM images are large; delete them once the run is confirmed.

```bash
tart delete bootstrap-test
tart delete bootstrap-test-clean
tart list                    # confirm nothing is left
```
