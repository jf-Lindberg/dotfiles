return {
  -- blink.cmp: completion engine. Rust-based matcher, so it stays responsive
  -- in large files where nvim-cmp starts to lag.
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "1.*", -- uses the prebuilt binary; no cargo toolchain needed
    dependencies = {
      "rafamadriz/friendly-snippets",
      { "folke/lazydev.nvim", ft = "lua" },
    },
    opts = {
      keymap = {
        preset = "default", -- <C-y> accepts, <C-n>/<C-p> cycle, <C-e> cancels
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
        },
        menu = { border = "rounded" },
        ghost_text = { enabled = true }, -- inline preview of the selected item
      },
      signature = { enabled = true, window = { border = "rounded" } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "lazydev" },
        providers = {
          -- lazydev feeds nvim API completions when editing this config.
          lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },

  -- Autopairs, with treesitter awareness so it doesn't fight with strings.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true },
  },

  -- Comment/uncomment with gcc and gc{motion}, correct for embedded languages
  -- (e.g. JS inside an HTML file).
  {
    "folke/ts-comments.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
