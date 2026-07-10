return {
  -- folke/tokyonight.nvim
  { "folke/tokyonight.nvim", lazy = true },
  -- catppuccin/nvim
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
  -- ellisonleao/gruvbox.nvim
  { "ellisonleao/gruvbox.nvim", lazy = true },
  -- rebelot/kanagawa.nvim
  { "rebelot/kanagawa.nvim", lazy = true },
  -- craftzdog/solarized-osaka.nvim
  { "craftzdog/solarized-osaka.nvim", lazy = true },
  -- navarasu/onedark.nvim
  { "navarasu/onedark.nvim", lazy = true },
  -- scottmckendry/cyberdream.nvim
  { "scottmckendry/cyberdream.nvim", lazy = true },
  -- neanias/everforest-nvim
  { "neanias/everforest-nvim", lazy = true },
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
