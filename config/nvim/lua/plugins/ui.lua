return {
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000, -- load before everything else so there's no flash of default colors
    opts = {
      style = "night",
      styles = { comments = { italic = true } },
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "tokyonight",
        globalstatus = true,
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
      },
      sections = {
        lualine_c = {
          { "filename", path = 1 }, -- path relative to cwd, so you know which file you're in
        },
        lualine_x = {
          -- Which LSP servers are attached to this buffer.
          {
            function()
              local clients = vim.lsp.get_clients({ bufnr = 0 })
              if #clients == 0 then
                return ""
              end
              local names = vim.tbl_map(function(c)
                return c.name
              end, clients)
              return " " .. table.concat(names, ",")
            end,
          },
          "encoding",
          "filetype",
        },
      },
    },
  },

  -- Buffer tabs across the top
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        show_buffer_close_icons = false,
        offsets = {
          { filetype = "neo-tree", text = "Explorer", highlight = "Directory", separator = true },
        },
      },
    },
  },

  -- File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file explorer" },
      { "<leader>o", "<cmd>Neotree focus<CR>", desc = "Focus file explorer" },
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true }, -- reveal the file you're editing
        use_libuv_file_watcher = true, -- react to changes made outside nvim
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = true,
        },
      },
      window = {
        width = 32,
        mappings = {
          ["<space>"] = "none", -- don't shadow the leader key
        },
      },
    },
  },

  -- Keymap discovery: press a prefix and wait, get a menu of what follows.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>m", group = "markdown" },
        { "<leader>s", group = "search" },
        { "<leader>u", group = "ui/toggle" },
        { "<leader>x", group = "diagnostics/quickfix" },
      },
    },
  },

  -- Indentation guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    opts = {
      indent = { char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
    },
  },

  -- Notifications, input/select popups, lazygit, and the picker (see editor.lua).
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      notifier = { enabled = true },
      indent = { enabled = false }, -- indent-blankline handles this
      input = { enabled = true },
      quickfile = { enabled = true },
      bigfile = { enabled = true }, -- disable heavy features in huge files
    },
    keys = {
      {
        "<leader>gg",
        function()
          require("snacks").lazygit()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>un",
        function()
          require("snacks").notifier.hide()
        end,
        desc = "Dismiss notifications",
      },
    },
  },
}
