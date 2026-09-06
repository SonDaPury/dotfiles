return {
  -- kevinhwang91/nvim-ufo: fold đẹp hơn native — preview nội dung khi hover, fold theo treesitter
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = { "BufReadPost" },
    init = function()
      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99      -- ufo cần giá trị lớn để mặc định không tự đóng fold
      vim.o.foldlevelstart = 99 -- mở file thì mọi fold đều đang mở sẵn
      vim.o.foldenable = true

      -- foldcolumn/foldenable là window-local nên phải tắt lại mỗi lần vào cửa sổ neo-tree
      -- (không dùng FileType vì neo-tree tái sử dụng buffer, cửa sổ mới sẽ không kích hoạt lại autocmd đó)
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        desc = "Tắt fold UI khi vào neo-tree — cây thư mục không cần fold",
        callback = function()
          if vim.bo.filetype == "neo-tree" or vim.bo.filetype == "neo-tree-popup" then
            vim.opt_local.foldcolumn = "0"
            vim.opt_local.foldenable = false
          end
        end,
      })
    end,
    keys = {
      { "zR", function() require("ufo").openAllFolds() end,               desc = "Open All Folds" },
      { "zM", function() require("ufo").closeAllFolds() end,              desc = "Close All Folds" },
      { "zK", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek Fold" },
    },
    config = function()
      require("ufo").setup({
        provider_selector = function()
          return { "treesitter", "indent" }
        end,
      })
    end,
  },
}
