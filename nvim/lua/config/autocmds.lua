local api = vim.api

local augroup = api.nvim_create_augroup
local autocmd = api.nvim_create_autocmd

-- HIGHLIGHT KHI COPY
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- AUTO RELOAD FILE KHI BỊ THAY ĐỔI NGOÀI
autocmd({ "FocusGained", "BufEnter" }, {
  group = augroup("checktime", { clear = true }),
  command = "checktime",
})

-- RESIZE SPLIT KHI ĐỔI KÍCH THƯỚC TERMINAL
autocmd("VimResized", {
  group = augroup("resize_splits", { clear = true }),
  command = "wincmd =",
})

-- fix conceallevel for json file
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc" },
  callback = function()
    vim.wo.spell = false
    vim.wo.conceallevel = 0
  end,
})

-- Tự động xóa khoảng trắng thừa cuối dòng khi save
vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "Xóa trailing whitespace trước khi lưu",
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Quay lại vị trí con trỏ lần cuối khi mở file
vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Nhớ vị trí cursor lần cuối",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Tắt autocomment khi xuống dòng mới (không tự thêm // hay # ở đầu dòng)
vim.api.nvim_create_autocmd("FileType", {
  desc = "Tắt continuation comment tự động",
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- Tự động đóng một số filetype bằng phím q
vim.api.nvim_create_autocmd("FileType", {
  desc = "Đóng cửa sổ bằng q cho các filetype phụ",
  pattern = {
    "qf", "help", "man", "notify", "lspinfo",
    "checkhealth", "startuptime",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})
