-- Khai báo LSP server ở đây: mason-lspconfig sẽ tự cài, lspconfig sẽ tự setup.
-- Thêm server mới = thêm 1 key vào bảng này, không cần sửa file nào khác.

-- Phải lấy on_attach mặc định của eslint (tạo lệnh LspEslintFixAll) TRƯỚC khi
-- vim.lsp.config("eslint", ...) ở lsp.lua ghi đè nó, nếu không sẽ bị đệ quy vô hạn.
local eslint_base_on_attach = vim.lsp.config.eslint and vim.lsp.config.eslint.on_attach

return {
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
      },
    },
  },
  -- gopls = {},
  clangd = {},
  vtsls = {},
  tailwindcss = {},
  html = {
    filetypes = { "html", "jsp" },
  },
  emmet_language_server = {
    filetypes = { "html", "css", "javascriptreact", "typescriptreact", "jsp" },
  },
  lemminx = {},
  cssls = {},
  jsonls = {},
  eslint = {
    on_attach = function(client, bufnr)
      if eslint_base_on_attach then
        eslint_base_on_attach(client, bufnr)
      end
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        command = "silent! LspEslintFixAll",
      })
    end,
  },
  pyright = {
    before_init = function(_, config)
      -- Tự động tìm virtualenv (.venv, venv, hoặc $VIRTUAL_ENV)
      -- để Pyright nhận diện đúng thư viện trong môi trường ảo
      local cwd = vim.fn.getcwd()
      local python_candidates = {
        cwd .. "/.venv/bin/python",
        cwd .. "/venv/bin/python",
        vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. "/bin/python"),
      }
      for _, path in ipairs(python_candidates) do
        if path and vim.fn.executable(path) == 1 then
          config.settings = config.settings or {}
          config.settings.python = config.settings.python or {}
          config.settings.python.pythonPath = path
          break
        end
      end
    end,
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "openFilesOnly",
        },
      },
    },
  },
  ruff = {
    on_attach = function(client)
      -- Tắt hover provider của ruff để nhường cho pyright hiển thị type doc đầy đủ
      client.server_capabilities.hoverProvider = false
    end,
  },
}
