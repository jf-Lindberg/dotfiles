return {
  -- Debug Adapter Protocol: breakpoints, stepping, variable inspection.
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        config = function()
          local dap, dapui = require("dap"), require("dapui")
          dapui.setup()
          -- Open the debug UI automatically when a session starts, close on exit.
          dap.listeners.after.event_initialized["dapui"] = dapui.open
          dap.listeners.before.event_terminated["dapui"] = dapui.close
          dap.listeners.before.event_exited["dapui"] = dapui.close
        end,
      },
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {}, -- shows variable values inline next to the code
      },
      {
        "leoluz/nvim-dap-go",
        ft = "go",
        opts = {}, -- wires up delve, including "debug nearest test"
      },
      {
        "mfussenegger/nvim-dap-python",
        ft = "python",
        config = function()
          require("dap-python").setup("python3")
        end,
      },
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue / start" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate session" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle debug UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Evaluate expression" },
    },
    config = function()
      -- Distinguish breakpoint signs from diagnostics in the gutter.
      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticWarn", linehl = "Visual" })
    end,
  },

  -- Test runner: run the nearest test, the file, or the whole suite, with
  -- results shown inline and in a summary panel.
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/nvim-nio",
      "fredrikaverpil/neotest-golang",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-jest",
    },
    keys = {
      { "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>tT", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run tests in file" },
      { "<leader>ta", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run all tests" },
      { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle test summary" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Show test output" },
      { "<leader>tp", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-golang"),
          require("neotest-python")({ dap = { justMyCode = false } }),
          require("neotest-jest"),
        },
      })
    end,
  },
}
