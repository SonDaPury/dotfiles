return {
  -- mason lsp config
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      {
        "neovim/nvim-lspconfig"
      },
      {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        config = function()
          require("mason").setup()
        end
      },
    },
    opts = {
      ensure_installed = {
        "lua_ls",
        "tailwindcss",
        "html",
        "cssls",
        "dockerls",
        "emmet_ls",
        "eslint",
        "ts_ls",
      },
    },

  },

  -- lsp config
  {
    "neovim/nvim-lspconfig",
    keys = {
      { "gd",         "<Cmd>lua vim.lsp.buf.definition()<CR>", mode = "n" },
      { "<leader>ca", "<Cmd>Lspsaga code_action<CR>",          mode = { "n", "v" } },
      { "K",          "<Cmd>lua vim.lsp.buf.hover()<CR>",      mode = "n" },
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lspconfig = require("lspconfig")
      local status_cmp_nvim_lsp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if not status_cmp_nvim_lsp then
        return
      end

      local capabilities = cmp_nvim_lsp.default_capabilities()
      local capabilities_css = vim.lsp.protocol.make_client_capabilities()
      capabilities_css.textDocument.completion.completionItem.snippetSupport = true

      -- emmet
      lspconfig.emmet_ls.setup({
        capabilities = capabilities,
      })

      -- docker
      lspconfig.dockerls.setup({
        capabilities = capabilities,
      })

      -- tsserver
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
      })

      -- eslint
      lspconfig.eslint.setup({
        capabilities = capabilities,
        on_attach = function(_, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
          })
        end,
      })

      -- css
      lspconfig.cssls.setup({
        capabilities = capabilities_css,
      })

      -- html
      lspconfig.html.setup({
        capabilities = capabilities_css,
      })

      -- tailwind
      lspconfig.tailwindcss.setup({
        {
          capabilities = capabilities,
        },
      })

      -- lua
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },

            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
          },
        },
      })

      vim.lsp.handlers["textDocument/publishDiagnostics"] =
          vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
            undercurl = true,
            update_in_insert = false,
            signs = true,
            -- virtual_text = { spacing = 4, prefix = "●" },
            severity_sort = true,
          })

      -- Diagnostic symbols in the sign column (gutter)
      local signs = { Error = "⛔", Warn = "⚠️ ", Hint = "💡", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end
    end,
  },

  -- cmp
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "rafamadriz/friendly-snippets",
      "saadparwaiz1/cmp_luasnip",
      "onsails/lspkind.nvim",
      { "L3MON4D3/LuaSnip", version = "v1.*" },
    },
    event = "InsertEnter",
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")

      lspkind.init({
        symbol_map = {
          Copilot = "",
        },
      })

      vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })

      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip").filetype_extend("javascript", { "javascriptreact" })
      require("luasnip").filetype_extend("typescript", { "javascriptreact" })
      require("luasnip").filetype_extend("typescriptreact", { "javascriptreact" })

      local has_words_before = function()
        if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
          return false
        end
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0
            and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
      end
      cmp.setup({
        mapping = {
          ["<Tab>"] = vim.schedule_wrap(function(fallback)
            if cmp.visible() and has_words_before() then
              cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
            else
              fallback()
            end
          end),
        },
      })

      cmp.setup({
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
            symbol_map = { Copilot = "" },
          }),
        },

        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        window = {
          -- completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
          { name = "copilot", group_index = 2 },
        }, {
          { name = "buffer" },
        }),
      })

      cmp.setup.filetype("gitcommit", {
        sources = cmp.config.sources({
          { name = "git" },
        }, {
          { name = "buffer" },
        }),
      })

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end,
  },

  -- formatter by conform
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          javascript = { { "prettier" } },
          typescript = { { "prettier" } },
          typescriptreact = { { "prettier" } },
          javascriptreact = { { "prettier" } },
          html = { { "prettier" } },
          css = { { "prettier" } },
          json = { { "prettier" } },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = "*",
          callback = function(args)
            require("conform").format({ bufnr = args.buf })
          end,
        }),
      })
    end,
  },

}
