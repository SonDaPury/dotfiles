return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  -- {
  --   "scottmckendry/cyberdream.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     transparent = true,
  --     italic_comments = true,
  --   },
  --   config = function(opts)
  --     require("cyberdream").setup(opts)
  --     vim.cmd("colorscheme cyberdream")
  --   end,
  -- },
}
