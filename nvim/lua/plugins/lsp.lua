return {
  -- ===================================================================
  -- 1. MASON: Trình quản lý các LSP server, linter, formatter
  -- ===================================================================
  -- {
  --   "williamboman/mason.nvim",
  --   opts = {
  --   },
  -- },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        -- "ts_ls",
        "lua_ls",
        "html",
        "cssls",
        "jsonls",
        "bashls",
        "vtsls",
      },
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },

  -- ===================================================================
  -- 2. NONE-LS: Tích hợp Formatter (như Prettier) vào LSP
  -- ===================================================================
  {
    "nvimtools/none-ls.nvim",
    dependencies = { "williamboman/mason.nvim" },

    config = function()
      local nls = require("null-ls")
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

      nls.setup({
        sources = {
          nls.builtins.formatting.prettier,
          nls.builtins.formatting.stylua,

          nls.builtins.diagnostics.eslint,
          nls.builtins.code_actions.eslint,
        },

        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ async = false })
              end,
            })
          end
        end,
      })
    end,
  },

  -- ===================================================================
  -- 3. LSPCONFIG: Cấu hình và kích hoạt các LSP server
  -- ===================================================================
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim", -- Vẫn cần thiết để làm cầu nối
      "nvimtools/none-ls.nvim",
      "saghen/blink.cmp",
      "pmizio/typescript-tools.nvim",
    },
    -- "opts" chứa toàn bộ cấu hình khai báo cho các server.
    opts = {
      servers = {
        bashls = {},
        cssls = {},
        html = {},
        jsonls = {},
        -- ts_ls = {
        -- },
        vtsls = {
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
          },
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                maxInlayHintLength = 30,
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
        },

        -- Tùy chỉnh riêng cho lua_ls, tất cả sẽ được truyền vào hàm setup.
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
      },
    },
    config = function(_, opts)
      vim.diagnostic.config({
        underline = true,

        virtual_text = {
          spacing = 4, -- Khoảng cách từ code đến virtual text
          prefix = "●", -- Ký tự đứng trước nội dung lỗi
        },

        signs = true,

        update_in_insert = false,

        float = {
          focusable = true,
          style = "minimal",
          border = "rounded",
          source = "always", -- Luôn hiển thị nguồn của lỗi (ví dụ: "eslint", "tsserver")
        },
      })
      local on_attach = function(client, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(
            mode,
            lhs,
            rhs,
            { buffer = bufnr, noremap = true, silent = true, desc = "LSP: " .. desc }
          )
        end
        -- map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
        map("n", "gr", vim.lsp.buf.references, "Go to References")
        map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("n", "<leader>sl", vim.diagnostic.open_float, "Show line diagnostic")
        -- map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
      end

      -- Bắt đầu vòng lặp để cấu hình từng server trong `opts.servers`
      local lspconfig = require("lspconfig")
      for server, config in pairs(opts.servers) do
        -- `config` ở đây là bảng bạn định nghĩa trong `opts.servers` (ví dụ: { settings = ...})

        -- Gán on_attach chung cho tất cả server.
        -- Dùng `config.on_attach or on_attach` để không ghi đè nếu bạn có on_attach riêng cho server đó.
        config.on_attach = config.on_attach or on_attach

        -- Trộn capabilities của blink.cmp vào.
        -- Dòng này rất thông minh, nó sẽ giữ lại capabilities riêng của bạn (nếu có)
        -- và thêm các capabilities của blink.cmp vào.
        config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)

        -- Gọi hàm setup cho server hiện tại với config đã được chuẩn bị.
        lspconfig[server].setup(config)
      end
    end,
  },

  -- 2. PLUGIN HOÀN THÀNH MÃ (BLINK.CMP)
  {
    "saghen/blink.cmp",
    lazy = false,
    priority = 100,
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    version = "1.*",
    opts = {
      keymap = {
        -- set to 'none' to disable the 'default' preset
        preset = "default",

        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<cr>"] = { "accept", "fallback" },

        -- disable a keymap from the preset
        ["<C-e>"] = { "hide", "fallback" },

        -- show with a list of providers
        ["<C-space>"] = {
          function(cmp)
            cmp.show({ providers = { "snippets" } })
          end,
        },
      },
      completion = {
        keyword = { range = "full" },
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
        menu = {
          auto_show = true,

          draw = {
            columns = {
              { "label",     "label_description", gap = 1 },
              { "kind_icon", "kind" },
            },
          },
        },
        ghost_text = { enabled = false },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      snippets = { preset = "default" },
      cmdline = { enabled = true },
    },
  },
}
