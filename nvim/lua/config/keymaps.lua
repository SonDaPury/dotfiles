-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = LazyVim.safe_keymap_set
-- map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "i" }, "jj", "<esc>", { desc = "Esc", silent = true })
map({ "n" }, "x", '"_x', { desc = "Delete without cut", silent = true })
map({ "v" }, "x", '"_x', { desc = "Delete without cut", silent = true })
map({ "n" }, "c", '"_c', { desc = "Delete without cut", silent = true })
map({ "n" }, "x", '"_x', { desc = "Delete without cut", silent = true })
map({ "v" }, "x", '"_x', { desc = "Delete without cut", silent = true })
map({ "v" }, "c", '"_c', { desc = "Delete without cut", silent = true })
map({ "n" }, "ss", ":split<Return>", { desc = "Delete without cut", silent = true })
map({ "n" }, "sv", ":vsplit<Return>", { desc = "Delete without cut", silent = true })
