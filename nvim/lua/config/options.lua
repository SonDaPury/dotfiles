local opt = vim.opt
local g = vim.g

opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

opt.number = true           -- số dòng tuyệt đối
opt.relativenumber = true   -- số dòng tương đối (di chuyển nhanh)

opt.cursorline = true       -- highlight dòng hiện tại
opt.signcolumn = "yes"      -- luôn chừa chỗ cho git / diagnostics

opt.tabstop = 2 -- độ rộng tab
opt.shiftwidth = 2 -- độ rộng khi thụt lề
opt.expandtab = true -- dùng space thay vì tab
opt.smartindent = true -- thụt lề thông minh theo cú pháp
opt.autoindent = true -- tự thụt lề dòng mới

opt.ignorecase = true -- không phân biệt hoa/thường
opt.smartcase = true -- nhưng phân biệt nếu có chữ hoa
opt.incsearch = true -- tìm ngay khi gõ
opt.hlsearch = true -- highlight kết quả tìm

opt.clipboard = "unnamedplus"

opt.undofile = true -- lưu lịch sử undo qua các session
opt.splitright = true      -- split dọc mở bên phải
opt.splitbelow = true      -- split ngang mở bên dưới
opt.mouse = "a"             -- bật chuột

opt.termguicolors = true  -- màu sắc đầy đủ (cần cho theme đẹp)


