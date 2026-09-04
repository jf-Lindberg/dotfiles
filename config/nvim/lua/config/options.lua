-- Core editor settings. Nothing here depends on a plugin being installed.

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

-- Line numbers: absolute for the current line, relative elsewhere, so that
-- motions like 8k are countable at a glance.
opt.number = true
opt.relativenumber = true

-- Indentation. Two spaces by default; per-language overrides live in autocmds.
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true -- ...unless the query contains a capital letter
opt.hlsearch = true
opt.incsearch = true

-- UI
opt.termguicolors = true
opt.signcolumn = "yes" -- always on, so the gutter doesn't jitter as diagnostics appear
opt.cursorline = true
opt.mouse = "a" -- drag selects buffer text; Option-drag still selects terminal cells
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.splitright = true
opt.splitbelow = true
opt.showmode = false -- the statusline already shows it
opt.laststatus = 3 -- one global statusline instead of one per split
opt.winborder = "rounded" -- 0.11+: rounded borders on all floating windows

-- Files and undo
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undo"
opt.updatetime = 250 -- drives CursorHold, and how fast diagnostics/git signs refresh
opt.timeoutlen = 400 -- how long to wait for a mapping sequence to complete

-- Completion behaviour
opt.completeopt = { "menu", "menuone", "noselect" }

-- Clipboard: share with macOS. Scheduled so it doesn't slow startup.
vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)

-- Show whitespace that usually matters
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Live substitution preview in a split
opt.inccommand = "split"

-- Markdown lives in this config's life (worklog), so make prose behave.
opt.linebreak = true
opt.conceallevel = 2 -- required for render-markdown.nvim to hide syntax
