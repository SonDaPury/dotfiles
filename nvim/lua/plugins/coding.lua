return {
  -- Telescrope
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<C-p>",
        "<cmd>Telescope find_files<cr>",
        desc = "find files within current working directory, respects .gitignore",
        mode = { "n", "i" },
      },
      {
        "<leader>fs",
        "<cmd>Telescope live_grep<cr>",
        desc = "find string in current working directory as you type",
      },
      {
        "<leader>fc",
        "<cmd>Telescope grep_string<cr>",
        desc = "find string under cursor in current working directory",
      },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "list open buffers in current neovim instance" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "list available help tags" },
    },
    config = function()
      local telescopeConfig = require("telescope.config")
      local telescope = require("telescope")
      local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
      table.insert(vimgrep_arguments, "--hidden")
      table.insert(vimgrep_arguments, "--glob")
      table.insert(vimgrep_arguments, "!**/.git/*")

      telescope.setup({
        defaults = {
          vimgrep_arguments = vimgrep_arguments,
        },
        pickers = {
          find_files = {
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
          },
        },
        extensions = {},
      })
    end,
  },

  -- Neotree
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      { "<C-n>", "<cmd>Neotree toggle<CR>", desc = "Neotree Toggle" },
      { "<leader>e", "<cmd>Neotree reveal<cr>", desc = "Neotree Reveal" },
    },
  },

  -- gitsigns
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
    },
  },

  -- liveserver
  {
    "barrett-ruth/live-server.nvim",
    cmd = { "LiveServerStart", "LiveServerStop" },
    config = function()
      require("live-server").setup()
    end,
  },

  -- blink cmp
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        ghost_text = {
          enabled = false,
        },
      },
    },
  },

  -- disable inlay_hints
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
    },
  },

  -- tmux nvim
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
}
