return {
  -- Treesitter gives real syntax trees: accurate highlighting, indentation,
  -- and structural text objects (change a whole function, select an argument).
  --
  -- NOTE: this uses the `main` branch. The older `master` branch explicitly does
  -- not support Neovim 0.12+, and pairing it with 0.12 causes parser ABI errors
  -- ("attempt to call method 'range'"). `main` is a rewrite: parser installation
  -- and highlighting are now opt-in per buffer rather than configured via setup().
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      local ensure = {
        "bash",
        "c",
        "css",
        "diff",
        "dockerfile",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "gitcommit",
        "gitignore",
        "html",
        "java",
        "javascript",
        "json",
        "lua",
        "luadoc",
        "make",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "sql",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      }

      -- Install anything missing, quietly, in the background.
      local installed = require("nvim-treesitter.config").get_installed("parsers")
      local missing = vim.tbl_filter(function(lang)
        return not vim.tbl_contains(installed, lang)
      end, ensure)
      if #missing > 0 then
        require("nvim-treesitter").install(missing)
      end

      -- On `main`, highlighting is started per buffer rather than globally.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
        callback = function(event)
          local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
          if not lang then
            return
          end
          -- Only start if a parser is actually present; otherwise fall back to
          -- regex syntax rather than throwing.
          if not vim.tbl_contains(require("nvim-treesitter.config").get_installed("parsers"), lang) then
            return
          end
          pcall(vim.treesitter.start, event.buf, lang)
          -- Treesitter-based indentation and folding.
          vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- Structural text objects: `vif` selects a function body, `daa` deletes an
  -- argument, `]f` jumps to the next function.
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select = require("nvim-treesitter-textobjects.select").select_textobject
      local objects = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["ai"] = "@conditional.outer",
        ["ii"] = "@conditional.inner",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
      }
      for lhs, obj in pairs(objects) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          select(obj, "textobjects")
        end, { desc = "Select " .. obj })
      end

      local move = require("nvim-treesitter-textobjects.move")
      vim.keymap.set({ "n", "x", "o" }, "]f", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "Next function" })
      vim.keymap.set({ "n", "x", "o" }, "[f", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "Previous function" })
      vim.keymap.set({ "n", "x", "o" }, "]c", function()
        move.goto_next_start("@class.outer", "textobjects")
      end, { desc = "Next class" })
      vim.keymap.set({ "n", "x", "o" }, "[c", function()
        move.goto_previous_start("@class.outer", "textobjects")
      end, { desc = "Previous class" })

      local swap = require("nvim-treesitter-textobjects.swap")
      vim.keymap.set("n", "<leader>cn", function()
        swap.swap_next("@parameter.inner")
      end, { desc = "Swap parameter next" })
      vim.keymap.set("n", "<leader>cp", function()
        swap.swap_previous("@parameter.inner")
      end, { desc = "Swap parameter previous" })
    end,
  },

  -- Keep the enclosing function/class header pinned to the top of the window
  -- while you scroll through a long body.
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = { max_lines = 3 },
    keys = {
      { "<leader>ut", "<cmd>TSContextToggle<CR>", desc = "Toggle sticky context" },
    },
  },
}
