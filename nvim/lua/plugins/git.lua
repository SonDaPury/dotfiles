return {
  -- lewis6991/gitsigns.nvim: hiện dấu thay đổi git ở gutter + inline blame cho dòng hiện tại
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = true,
    },
  },
}
