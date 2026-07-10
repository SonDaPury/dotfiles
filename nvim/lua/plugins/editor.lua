return {
  -- windwp/nvim-autopairs: tự động đóng ngoặc/dấu ngoặc kép khi gõ
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  -- kylechui/nvim-surround: thêm/sửa/xóa ký tự bao quanh (ngoặc, quote, tag...)
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    init = function()
      -- Từ nvim-surround v4, keymap không còn cấu hình qua setup() nữa,
      -- phải tắt mapping mặc định rồi tự bind vào <Plug> (xem :h nvim-surround.migrating.v3_to_v4)
      vim.g.nvim_surround_no_mappings = true
    end,
    config = function()
      require("nvim-surround").setup({})

      -- sa = surround add, sd = surround delete, sr = surround replace
      vim.keymap.set("n", "sa", "<Plug>(nvim-surround-normal)", { desc = "Add Surround" })
      vim.keymap.set("x", "sa", "<Plug>(nvim-surround-visual)", { desc = "Add Surround" })
      vim.keymap.set("n", "sd", "<Plug>(nvim-surround-delete)", { desc = "Delete Surround" })
      vim.keymap.set("n", "sr", "<Plug>(nvim-surround-change)", { desc = "Change Surround" })
    end,
  },

  -- turbo console log
  {
    "gaelph/logsitter.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      {
        "<leader>lg",
        function()
          require("logsitter").log()
        end,
        mode = "n",
        desc = "Logsitter: Insert Log",
      },
      {
        "<leader>lg",
        function()
          require("logsitter").log_visual()
        end,
        mode = "x",
        desc = "Logsitter: Insert Log (Visual)",
      },
    },
  },
}
