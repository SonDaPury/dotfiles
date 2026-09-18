return {
  -- folke/tokyonight.nvim
  { "folke/tokyonight.nvim",    lazy = true },
  -- catppuccin/nvim
  { "catppuccin/nvim",          name = "catppuccin", lazy = true },
  -- ellisonleao/gruvbox.nvim
  { "ellisonleao/gruvbox.nvim", lazy = true },
  -- rebelot/kanagawa.nvim
  { "rebelot/kanagawa.nvim",    lazy = true },
  -- craftzdog/solarized-osaka.nvim
  {
    "craftzdog/solarized-osaka.nvim",
    lazy = true,
    priority = 1000,
    opts = {
      on_colors = function(colors)
        -- colors.yellow200 = "#ffd84d"
      end,
      on_highlights = function(hl, c)
        -- Cấu hình cho nhóm được tìm thấy từ lệnh :Inspect
        -- hl["@variable.javascript"] = { fg = c.yellow200, } -- Dùng biến màu yellow đã sửa ở trên
        -- hl["String"] = { fg = "#00FF00", italic = true } -- Truyền trực tiếp mã màu hex
        -- hl["@variable"] = { fg = c.blue }
      end,
    }
  },
  -- navarasu/onedark.nvim
  { "navarasu/onedark.nvim",         lazy = true },
  -- scottmckendry/cyberdream.nvim
  { "scottmckendry/cyberdream.nvim", lazy = true },
  -- neanias/everforest-nvim
  { "neanias/everforest-nvim",       lazy = true },
  -- Mofiqul/dracula.nvim: theme mặc định khi mở nvim lần đầu, trước khi chọn qua picker
  {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("dracula")
    end,
  },

  -- zaldih/themery.nvim: picker chọn colorscheme, tự lưu lựa chọn và áp dụng lại cho các lần mở nvim sau
  {
    "zaldih/themery.nvim",
    lazy = false,
    keys = {
      { "<leader>th", "<cmd>Themery<cr>", desc = "Theme Picker" },
    },
    opts = {
      themes = {
        "tokyonight",
        "catppuccin",
        "gruvbox",
        "kanagawa",
        "solarized-osaka",
        "dracula",
        "onedark",
        "cyberdream",
        {
          name = "everforest-soft",
          colorscheme = "everforest",
          before = [[require("everforest").setup({ background = "soft" })]],
        },
        {
          name = "everforest-medium",
          colorscheme = "everforest",
          before = [[require("everforest").setup({ background = "medium" })]],
        },
        {
          name = "everforest-hard",
          colorscheme = "everforest",
          before = [[require("everforest").setup({ background = "hard" })]],
        },
      },
      livePreview = true,
    },
  },
}
