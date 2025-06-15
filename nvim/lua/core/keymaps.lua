local map = vim.keymap.set

vim.g.mapleader = " "
map({ "i" }, "jj", "<esc>", { desc = "Esc", silent = true })
map({ "n" }, "x", '"_x', { desc = "Delete without cut", silent = true })
map({ "v" }, "x", '"_x', { desc = "Delete without cut", silent = true })
map({ "n" }, "c", '"_c', { desc = "Delete without cut", silent = true })
map({ "n" }, "x", '"_x', { desc = "Delete without cut", silent = true })
map({ "v" }, "x", '"_x', { desc = "Delete without cut", silent = true })
map({ "v" }, "c", '"_c', { desc = "Delete without cut", silent = true })
map({ "n" }, "ss", ":split<Return>", { desc = "Delete without cut", silent = true })
map({ "n" }, "sv", ":vsplit<Return>", { desc = "Delete without cut", silent = true })
map({ "i" }, "<C-s>", "<esc>:w<cr>", { desc = "Ctrl+S to save", silent = true })
map({ "n" }, "<C-s>", ":w<cr>", { desc = "Ctrl+S to save", silent = true })
map({ "n" }, "<C-n>", ":enew<CR>", { desc = "Create a new file", silent = true })
map("v", "<Tab>", ">gv", { noremap = true, silent = true })
map("v", "<S-Tab>", "<gv", { noremap = true, silent = true })
map("n", "<leader>rn", ":IncRename ", { silent = true })
