-- Khai báo LSP server ở đây: mason-lspconfig sẽ tự cài, lspconfig sẽ tự setup.
-- Thêm server mới = thêm 1 key vào bảng này, không cần sửa file nào khác.

-- Phải lấy on_attach mặc định của eslint (tạo lệnh LspEslintFixAll) TRƯỚC khi
-- vim.lsp.config("eslint", ...) ở lsp.lua ghi đè nó, nếu không sẽ bị đệ quy vô hạn.
local eslint_base_on_attach = vim.lsp.config.eslint.on_attach

return {
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
      },
    },
  },
  gopls = {},
  clangd = {},
  vtsls = {},
  tailwindcss = {},
  html = {},
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
}
