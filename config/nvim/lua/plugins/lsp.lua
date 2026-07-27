return {
  -- Mason installs language servers, formatters and linters into
  -- ~/.local/share/nvim/mason/bin, so they don't pollute the system.
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<CR>", desc = "Mason (LSP installer)" } },
    opts = {
      ui = { border = "rounded" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
      -- Better Lua completion for editing this config itself.
      { "folke/lazydev.nvim", ft = "lua", opts = {} },
    },
    config = function()
      -- Diagnostics presentation: virtual text with a prefix, plus gutter icons.
      vim.diagnostic.config({
        virtual_text = { spacing = 2, prefix = "●", source = "if_many" },
        severity_sort = true,
        float = { border = "rounded", source = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      })

      -- Buffer-local keymaps, attached only once a server is actually running.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(event)
          local buf = event.buf
          local function map(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = buf, desc = "LSP: " .. desc })
          end

          local snacks = require("snacks")

          -- Navigation. These use snacks.picker so results land in a fuzzy-filterable
          -- list rather than dumping straight into the quickfix window.
          map("gd", snacks.picker.lsp_definitions, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gr", snacks.picker.lsp_references, "Find usages (references)")
          map("gI", snacks.picker.lsp_implementations, "Go to implementation")
          map("gy", snacks.picker.lsp_type_definitions, "Go to type definition")
          map("<leader>cs", snacks.picker.lsp_symbols, "Document symbols")
          map("<leader>cS", snacks.picker.lsp_workspace_symbols, "Workspace symbols")

          -- Documentation and signature help
          map("K", function()
            vim.lsp.buf.hover({ border = "rounded" })
          end, "Hover documentation")
          map("<C-k>", function()
            vim.lsp.buf.signature_help({ border = "rounded" })
          end, "Signature help", "i")

          -- Refactoring
          map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "v" })

          -- Diagnostics
          map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end

          -- Highlight other occurrences of the symbol under the cursor.
          if client:supports_method("textDocument/documentHighlight") then
            local hl_group = vim.api.nvim_create_augroup("user_lsp_highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              group = hl_group,
              buffer = buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              group = hl_group,
              buffer = buf,
              callback = vim.lsp.buf.clear_references,
            })
          end

          -- Inlay hints (parameter names, inferred types), toggleable.
          if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
            map("<leader>uh", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
            end, "Toggle inlay hints")
          end
        end,
      })

      -- Advertise blink.cmp's completion capabilities to every server.
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Per-server overrides. Anything not listed here uses upstream defaults.
      local servers = {
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              usePlaceholders = true,
              analyses = {
                unusedparams = true,
                unusedwrite = true,
                nilness = true,
                shadow = true,
              },
              staticcheck = true,
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },

        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              codeLens = { enable = true },
              hint = { enable = true },
              diagnostics = { globals = { "vim" } },
            },
          },
        },

        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                inlayHints = {
                  variableTypes = true,
                  functionReturnTypes = true,
                  callArgumentNames = true,
                },
              },
            },
          },
        },

        -- ruff handles linting and import sorting; basedpyright does the types.
        ruff = {},

        vtsls = {
          settings = {
            typescript = {
              inlayHints = {
                parameterNames = { enabled = "literals" },
                variableTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
              },
            },
          },
        },

        eslint = {},
        bashls = {},
        jsonls = {},
        yamlls = {},
        marksman = {}, -- markdown: link following, heading rename, workspace symbols
        taplo = {}, -- toml
      }

      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_enable = true,
      })

      -- Neovim 0.11+ config API: merge our overrides on top of lspconfig defaults.
      for name, cfg in pairs(servers) do
        cfg.capabilities = capabilities
        vim.lsp.config(name, cfg)
      end

      -- Extra tools that aren't language servers (formatters, linters, debuggers).
      require("mason-tool-installer").setup({
        ensure_installed = {
          "stylua",
          "prettierd",
          "gofumpt",
          "goimports",
          "shfmt",
          "google-java-format",
          "delve",
          "js-debug-adapter",
        },
      })
    end,
  },

  -- Java needs its own plugin: jdtls is stateful and per-project, so it can't
  -- be driven by the standard lspconfig lifecycle.
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      local jdtls_ok, jdtls = pcall(require, "jdtls")
      if not jdtls_ok then
        return
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        group = vim.api.nvim_create_augroup("user_jdtls", { clear = true }),
        callback = function()
          local mason = vim.fn.stdpath("data") .. "/mason"
          local root = vim.fs.root(0, { "pom.xml", "gradlew", "mvnw", ".git" })
          if not root then
            return
          end

          -- jdtls keeps a per-project workspace of indexes and build state.
          local workspace = vim.fn.stdpath("cache") .. "/jdtls/" .. vim.fn.fnamemodify(root, ":p:h:t")

          local launcher = vim.fn.glob(mason .. "/share/jdtls/plugins/org.eclipse.equinox.launcher_*.jar")
          if launcher == "" then
            vim.notify("jdtls not installed — run :MasonInstall jdtls", vim.log.levels.WARN)
            return
          end

          jdtls.start_or_attach({
            cmd = {
              vim.fn.exepath("java"),
              "-Declipse.application=org.eclipse.jdt.ls.core.id1",
              "-Dosgi.bundles.defaultStartLevel=4",
              "-Declipse.product=org.eclipse.jdt.ls.core.product",
              "-Dlog.protocol=true",
              "-Dlog.level=ALL",
              "-Xmx2g",
              "--add-modules=ALL-SYSTEM",
              "--add-opens",
              "java.base/java.util=ALL-UNNAMED",
              "--add-opens",
              "java.base/java.lang=ALL-UNNAMED",
              "-jar",
              launcher,
              "-configuration",
              mason .. "/share/jdtls/config",
              "-data",
              workspace,
            },
            root_dir = root,
            settings = {
              java = {
                format = { enabled = true },
                signatureHelp = { enabled = true },
                contentProvider = { preferred = "fernflower" }, -- decompile .class files
                inlayHints = { parameterNames = { enabled = "all" } },
                completion = {
                  favoriteStaticMembers = {
                    "org.junit.jupiter.api.Assertions.*",
                    "org.mockito.Mockito.*",
                  },
                },
              },
            },
            init_options = { bundles = {} },
          })
        end,
      })
    end,
  },
}
