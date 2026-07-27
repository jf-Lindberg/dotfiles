return {
  -- Fuzzy finder / picker. Provided by snacks.nvim (already loaded in ui.lua),
  -- so this spec only adds the keymaps and picker configuration.
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        enabled = true,
        ui_select = true, -- route vim.ui.select through the picker
        layout = { preset = "telescope" },
      },
      gitbrowse = { enabled = true },
    },
    keys = {
      -- Files and buffers
      { "<leader><space>", function() require("snacks").picker.files() end, desc = "Find files" },
      { "<leader>ff", function() require("snacks").picker.files() end, desc = "Find files" },
      { "<leader>fr", function() require("snacks").picker.recent() end, desc = "Recent files" },
      { "<leader>fb", function() require("snacks").picker.buffers() end, desc = "Buffers" },
      { "<leader>fc", function() require("snacks").picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find config file" },

      -- Text search across the project (ripgrep-backed)
      { "<leader>/", function() require("snacks").picker.grep() end, desc = "Grep project" },
      { "<leader>sg", function() require("snacks").picker.grep() end, desc = "Grep project" },
      { "<leader>sw", function() require("snacks").picker.grep_word() end, desc = "Grep word under cursor", mode = { "n", "x" } },
      { "<leader>sb", function() require("snacks").picker.lines() end, desc = "Search in buffer" },

      -- Vim internals
      { "<leader>sh", function() require("snacks").picker.help() end, desc = "Help pages" },
      { "<leader>sk", function() require("snacks").picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sc", function() require("snacks").picker.command_history() end, desc = "Command history" },
      { "<leader>sd", function() require("snacks").picker.diagnostics() end, desc = "Workspace diagnostics" },
      { "<leader>sr", function() require("snacks").picker.resume() end, desc = "Resume last picker" },
      { "<leader>su", function() require("snacks").picker.undo() end, desc = "Undo history" },

      -- Git
      { "<leader>gl", function() require("snacks").picker.git_log() end, desc = "Git log" },
      { "<leader>gs", function() require("snacks").picker.git_status() end, desc = "Git status" },
      { "<leader>gB", function() require("snacks").gitbrowse() end, desc = "Open in browser (git)", mode = { "n", "v" } },
    },
  },

  -- Git signs in the gutter, hunk staging, and inline blame.
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
        end

        map("n", "]h", gs.next_hunk, "Next git hunk")
        map("n", "[h", gs.prev_hunk, "Previous git hunk")
        map({ "n", "v" }, "<leader>gh", gs.stage_hunk, "Stage hunk")
        map({ "n", "v" }, "<leader>gr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, "Blame line")
        map("n", "<leader>gd", gs.diffthis, "Diff this file")
        map("n", "<leader>ub", gs.toggle_current_line_blame, "Toggle inline blame")
      end,
    },
  },

  -- A dedicated diagnostics / references / quickfix panel.
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = { focus = true },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (workspace)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (buffer)" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<CR>", desc = "Symbol outline" },
      { "<leader>xr", "<cmd>Trouble lsp toggle<CR>", desc = "References / definitions panel" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
    },
  },

  -- Project-wide find and replace, with a preview of every change before you commit.
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {},
    keys = {
      {
        "<leader>sR",
        function()
          require("grug-far").open({ transient = true })
        end,
        desc = "Search and replace (project)",
      },
    },
  },

  -- Surround: cs"' to change quotes, ysiw) to wrap a word, ds( to delete.
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },

  -- Jump anywhere on screen with s{char}{char}.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash jump" },
      { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter select" },
    },
  },

  -- Session persistence: reopen the files and layout you had per directory.
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>Ss", function() require("persistence").load() end, desc = "Restore session (this dir)" },
      { "<leader>Sl", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    },
  },

  -- Terminal toggling without leaving nvim.
  {
    "akinsho/toggleterm.nvim",
    keys = {
      { "<C-\\>", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", desc = "Floating terminal" },
    },
    opts = {
      open_mapping = [[<C-\>]],
      direction = "horizontal",
      size = 15,
      float_opts = { border = "rounded" },
    },
  },
}
