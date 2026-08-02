# File references

When naming a file in a response — a path the user may want to open — write it
as an **absolute path** (`/Users/flindberg/dev/repos/worklog/docs/spec.md`),
not relative to the current working directory.

The user cmd-clicks these paths in iTerm2. iTerm2 resolves a relative path
against the *interactive shell's* directory, which is not the agent's: the
agent changes directories freely inside its own subprocesses, and none of that
is visible to the terminal. A relative path that is correct for the agent is
therefore usually wrong for the shell, and iTerm2 falls through to opening it
in a web browser instead of the editor.

Append `:LINE` when pointing at a specific line
(`/Users/flindberg/dev/repos/dotfiles/steps/30-dotfiles.sh:23`).

This applies to prose. Leave paths inside command output, diffs, quoted file
contents, and code unchanged — they are data, not references to follow.
