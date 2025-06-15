-- Tự động cài đặt lazy.nvim nếu chưa có
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- phiên bản ổn định mới nhất
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Gọi các file cấu hình cốt lõi khác
require("core.options")
require("core.keymaps")

-- Thiết lập lazy.nvim
require("lazy").setup({
    spec = {
        -- Tự động import tất cả các file trong thư mục 'plugins'
        { import = "plugins" },
    },
    -- Các tùy chọn khác của lazy...
    change_detection = {
        enabled = true,
        notify = true, -- không hiện thông báo mỗi khi có thay đổi
    },
})
