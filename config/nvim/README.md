# Neovim config

Leader is `<Space>`. Press `<Space>` and wait to see available keys (which-key).

## Layout

```
init.lua              entry point
lua/config/
  options.lua         editor settings
  lazy.lua            plugin manager bootstrap
  keymaps.lua         general keymaps
  autocmds.lua        autocommands
lua/plugins/
  ui.lua              colorscheme, statusline, file tree, which-key
  lsp.lua             language servers, Mason, jdtls
  completion.lua      blink.cmp, autopairs
  treesitter.lua      syntax trees, text objects
  editor.lua          picker, git, trouble, search/replace
  format.lua          conform (format), nvim-lint
  markdown.lua        rendering + browser preview
  dap.lua             debugger + test runner
```

## Code navigation (LSP)

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `gr` | **Find usages / references** |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `gD` | Go to declaration |
| `K` | Hover documentation |
| `<C-k>` | Signature help (insert mode) |
| `<leader>cs` | Document symbols (outline) |
| `<leader>cS` | Workspace symbols |
| `<leader>cr` | Rename symbol (project-wide) |
| `<leader>ca` | Code action |
| `<leader>cd` | Show line diagnostics |
| `<leader>uh` | Toggle inlay hints |

## Finding things

| Key | Action |
| --- | --- |
| `<leader><space>` / `<leader>ff` | Find files |
| `<leader>/` / `<leader>sg` | Grep across project |
| `<leader>sw` | Grep word under cursor |
| `<leader>fb` | Switch buffer |
| `<leader>fr` | Recent files |
| `<leader>sb` | Search within buffer |
| `<leader>sd` | All workspace diagnostics |
| `<leader>sk` | Search keymaps |
| `<leader>sh` | Search help |
| `<leader>sR` | Project find & replace (previewed) |
| `<leader>sr` | Resume last picker |
| `s` | Flash jump to any visible location |

## Diagnostics panel (Trouble)

| Key | Action |
| --- | --- |
| `<leader>xx` | Workspace diagnostics |
| `<leader>xX` | Buffer diagnostics |
| `<leader>xs` | Symbol outline |
| `<leader>xr` | References panel |

## Files, git, terminal

| Key | Action |
| --- | --- |
| `<leader>e` | Toggle file explorer |
| `<leader>gg` | Lazygit |
| `<leader>gh` / `<leader>gr` | Stage / reset hunk |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Blame line |
| `<leader>gd` | Diff current file |
| `]h` / `[h` | Next / previous git hunk |
| `<C-t>` | Toggle terminal (`<leader>tf` for a float) |

## Markdown

| Key | Action |
| --- | --- |
| `<leader>mp` | **Toggle browser preview** (live reload) |
| `<leader>mr` | Toggle in-editor rendering |
| `<leader>mt` | Toggle table mode |
| `<CR>` | Follow link under cursor |
| `]l` / `[l` | Next / previous link |

## Editing

| Key | Action |
| --- | --- |
| `<leader>cf` | Format buffer |
| `<leader>uf` | Toggle format-on-save |
| `gcc` / `gc{motion}` | Comment |
| `vif` / `vaf` | Select inside / around function |
| `via` / `vaa` | Select inside / around argument |
| `]f` / `[f` | Next / previous function |
| `<C-space>` | Expand selection to parent node |
| `cs"'` | Change surrounding quotes |
| `ysiw)` | Surround word with parens |

## Debug & test

| Key | Action |
| --- | --- |
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Start / continue |
| `<leader>do` / `<leader>di` / `<leader>dO` | Step over / into / out |
| `<leader>du` | Toggle debug UI |
| `<leader>tt` | Run nearest test |
| `<leader>tT` | Run tests in file |
| `<leader>td` | Debug nearest test |
| `<leader>ts` | Test summary panel |

## Maintenance

- `:Lazy` — plugin manager (`U` updates, `X` cleans)
- `:Mason` — install/update language servers (`<leader>cm`)
- `:checkhealth` — diagnose problems
- `:ConformInfo` — see which formatter applies to a buffer
- `:LspInfo` — see attached servers

## External dependencies

Installed via Homebrew: `neovim`, `ripgrep`, `fd`, `lazygit`, `tree-sitter-cli`.

`tree-sitter-cli` is required — nvim-treesitter's `main` branch compiles parsers
with it. Note the `tree-sitter` formula is only the C library; the CLI is a
separate formula.

## Notes

- nvim-treesitter tracks the **`main`** branch. The older `master` branch does
  not support Neovim 0.12+ and produces `attempt to call method 'range'` errors.
- Java uses nvim-jdtls rather than plain lspconfig, since jdtls needs a
  per-project workspace directory.
- Format-on-save is on by default; `<leader>uf` disables it for the session.
