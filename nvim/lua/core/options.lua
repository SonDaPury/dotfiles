local opt = vim.opt

-- Giao diện
opt.number = true         -- Hiển thị số dòng
opt.relativenumber = true -- Hiển thị số dòng tương đối
opt.termguicolors = true  -- Bật màu 24-bit
opt.signcolumn = "yes"    -- Luôn hiển thị cột sign

-- Canh lề & Tab
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true -- Dùng space thay cho tab
opt.autoindent = true

-- Tìm kiếm
opt.ignorecase = true -- Không phân biệt hoa/thường khi tìm kiếm
opt.smartcase = true  -- Nhưng nếu có chữ hoa thì sẽ phân biệt

-- Khác
opt.clipboard = "unnamedplus" -- Đồng bộ clipboard với hệ thống
opt.swapfile = false          -- Tắt file swap
opt.cursorline = true         -- Highlight dòng hiện tại

-- Tắt netrw, để neo-tree làm trình quản lý file mặc định
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.fn.sign_define("DiagnosticSignError", { text = " ", texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn", { text = " ", texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInfo", { text = " ", texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint", { text = "󰌵", texthl = "DiagnosticSignHint" })

-- vim.o.foldcolumn = "1"
vim.o.foldlevel = 99
-- vim.o.foldlevelstart = 99
-- vim.o.foldenable = true
-- vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
