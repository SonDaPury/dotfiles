return {
  -- mfussenegger/nvim-dap: DAP client core
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      -- rcarriga/nvim-dap-ui: panel breakpoints/variables/call stack/watch/REPL
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
      },
      -- theHamsta/nvim-dap-virtual-text: hiện giá trị biến ngay cạnh dòng code lúc debug
      "theHamsta/nvim-dap-virtual-text",
      -- jay-babu/mason-nvim-dap.nvim: tự tải debug adapter qua mason, tương tự mason-lspconfig cho LSP
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = { "mason-org/mason.nvim" },
      },
      -- mxsdev/nvim-dap-vscode-js: nối js-debug-adapter (mason cài) vào nvim-dap thành adapter pwa-node/pwa-chrome
      -- (mason-nvim-dap không có handler tự động cho js-debug-adapter nên cần plugin này cấu hình riêng)
      "mxsdev/nvim-dap-vscode-js",
    },
    keys = {
      { "<leader>dc", function() require("dap").continue() end,          desc = "Continue" },
      { "<leader>di", function() require("dap").step_into() end,         desc = "Step Into" },
      { "<leader>do", function() require("dap").step_over() end,         desc = "Step Over" },
      { "<leader>dO", function() require("dap").step_out() end,          desc = "Step Out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Condition: "))
        end,
        desc = "Conditional Breakpoint",
      },
      { "<leader>du", function() require("dapui").toggle() end,    desc = "Toggle Dap UI" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dt", function() require("dap").terminate() end,   desc = "Terminate" },
      { "<leader>dl", function() require("dap").run_last() end,    desc = "Run Last" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      require("mason-nvim-dap").setup({
        ensure_installed = { "js-debug-adapter", "codelldb" },
        automatic_installation = true,
        -- handlers phải có (kể cả rỗng) thì mason-nvim-dap mới tự đăng ký dap.adapters cho package đã cài
        handlers = {},
      })

      require("dap-vscode-js").setup({
        debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
        adapters = { "pwa-node", "pwa-chrome" },
      })

      -- JS/TS/React/Angular/Vue/Next.js/Nest.js: dùng chung adapter vscode-js-debug (pwa-node/pwa-chrome)
      local js_filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" }
      for _, language in ipairs(js_filetypes) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch Node file",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to Node process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome (localhost)",
            url = function()
              return vim.fn.input("URL: ", "http://localhost:3000")
            end,
            webRoot = "${workspaceFolder}",
          },
        }
      end

      -- C++: codelldb
      dap.configurations.cpp = {
        {
          type = "codelldb",
          request = "launch",
          name = "Launch executable",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      dap.configurations.c = dap.configurations.cpp
    end,
  },
}
