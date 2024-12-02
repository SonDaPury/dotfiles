-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.g.mapleader = " "

local keymap = vim.keymap

-- Paste in insert mode
keymap.set("i", "<C-v>", '<C-r>"')

-- general keymaps
keymap.set("i", "jj", "<ESC>")
-- keymap.set("i", "<C-s>", "<ESC>:w<CR>")
-- keymap.set("n", "<C-s>", ":w<CR>")
keymap.set("n", "<CR>", ":nohl<CR>")
keymap.set("n", "x", '"_x')
keymap.set("v", "x", '"_x')
keymap.set("n", "c", '"_c')
keymap.set("v", "c", '"_c')
-- keymap.set("n", "<S-h>", ":bprev<CR>")
-- keymap.set("n", "<S-l>", ":bnext<CR>")
-- keymap.set("n", "<leader>bd", "<cmd>lua MiniBufremove.delete()<CR>")
keymap.set("i", "<C-j>", "<enter>")
keymap.set("i", "<C-v>", '<esc>"+pi')
keymap.set("n", "ss", ":split<Return>")
keymap.set("n", "sv", ":vsplit<Return>")
-- keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>")
keymap.set("n", "<A-Left>", ":-tabmove<cr>")
