return {
  -- In-buffer rendering: headings, tables, code blocks, checkboxes and callouts
  -- are drawn inline. Requires conceallevel=2 (set in config/options.lua).
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "quarto" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      heading = { sign = false, width = "block", left_pad = 0, right_pad = 2 },
      code = { sign = false, width = "block", right_pad = 2 },
      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
      },
    },
    keys = {
      { "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle inline rendering" },
    },
  },

  -- Browser preview with live reload and synced scrolling.
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    init = function()
      vim.g.mkdp_theme = "dark"
      vim.g.mkdp_auto_close = true
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", ft = "markdown", desc = "Toggle browser preview" },
    },
  },

  -- Editing quality-of-life: continue lists on <CR>, renumber ordered lists,
  -- toggle checkboxes, and format tables as you type.
  {
    "bullets-vim/bullets.vim",
    ft = { "markdown", "text", "gitcommit" },
  },

  {
    "dhruvasagar/vim-table-mode",
    ft = { "markdown" },
    init = function()
      vim.g.table_mode_corner = "|" -- GitHub-flavoured markdown tables
    end,
    keys = {
      { "<leader>mt", "<cmd>TableModeToggle<CR>", ft = "markdown", desc = "Toggle table mode" },
    },
  },

  -- Follow [links](...) between notes, and jump to headings. Complements the
  -- marksman LSP, which handles workspace-wide link and heading intelligence.
  {
    "jakewvincent/mkdnflow.nvim",
    ft = "markdown",
    opts = {
      modules = { conceal = false }, -- render-markdown.nvim owns concealing
      mappings = {
        MkdnEnter = { { "n", "v" }, "<CR>" }, -- follow link / toggle item under cursor
        MkdnTab = false,
        MkdnSTab = false,
        MkdnNextLink = { "n", "]l" },
        MkdnPrevLink = { "n", "[l" },
        MkdnFoldSection = false,
        MkdnUnfoldSection = false,
      },
    },
  },
}
