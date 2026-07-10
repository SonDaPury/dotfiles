return {
  -- nvim-telescope/telescope.nvim: find files / live grep kiểu VSCode (Cmd+P / Cmd+Shift+F)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Live Grep" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          layout_strategy = "vertical",
        },
      })
      require("telescope").load_extension("fzf")
    end,
  },
}
