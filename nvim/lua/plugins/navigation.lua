return {
  -- christoomey/vim-tmux-navigator: di chuyển liền mạch giữa split vim và pane tmux bằng Ctrl-h/j/k/l
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },

  -- Neotree
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle NeoTree" },
      { "<leader>E", ":Neotree reveal<cr>",     mode = "n",             silent = true, desc = "Toggle neotree reveal" },
    },
    opts = {
      window = {
        position = "left",
        width = 40,
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          -- expander_collapsed = "",
          -- expander_expanded = "",
          expander_highlight = "NeoTreeExpander",
        },
      },
      -- tự cuộn/highlight tới file đang mở trong cây, giữ nguyên các thư mục đã mở rộng trước đó
      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
      },
    },
  },
}
