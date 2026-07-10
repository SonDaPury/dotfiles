local map = vim.keymap.set

-- Diagnostic keymaps: hoạt động độc lập với LSP attach (diagnostic có thể đến từ nvim-lint)
map("n", "<leader>sl", "<cmd>Lspsaga show_line_diagnostics<cr>", { desc = "Show Line Diagnostic" })
map("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<cr>", { desc = "Prev Diagnostic" })
map("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<cr>", { desc = "Next Diagnostic" })

-- LSP keymaps: chỉ active trên buffer đã có LSP client attach
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),
  callback = function(event)
    local opts = { buffer = event.buf }
    map("n", "gd", "<cmd>Lspsaga peek_definition<cr>", vim.tbl_extend("force", opts, { desc = "Peek Definition" }))
    map("n", "gr", "<cmd>Lspsaga finder<cr>", vim.tbl_extend("force", opts, { desc = "Find References" }))
    map("n", "K", "<cmd>Lspsaga hover_doc<cr>", { desc = "Hover docs" })
    map("n", "<leader>rn", "<cmd>Lspsaga rename<cr>", vim.tbl_extend("force", opts, { desc = "Rename" }))
    map("n", "<leader>ca", "<cmd>Lspsaga code_action<cr>", vim.tbl_extend("force", opts, { desc = "Code Action" }))
  end,
})
