return {
  ---------------------------------------------------------------------------------------------------------------------------------------
  -- autopair
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  ---------------------------------------------------------------------------------------------------------------------------------------
  -- autotag
  {
    "windwp/nvim-ts-autotag",
    opts = {
      enable_close = true,  -- Auto close tags
      enable_rename = true, -- Auto rename pairs of tags
      enable_close_on_slash = false,
    },
  },

  ---------------------------------------------------------------------------------------------------------------------------------------
  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = { { "nvim-lua/plenary.nvim" } },
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
      { "<leader>fb", "<cmd>Telescope buffers<cr>",   desc = "list open buffers in current neovim instance" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "list available help tags" },
    },
    config = function()
      local telescopeConfig = require("telescope.config")
      local telescope = require("telescope")
      local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
      table.insert(vimgrep_arguments, "--hidden")
      table.insert(vimgrep_arguments, "--glob")
      table.insert(vimgrep_arguments, "!**/.git/*")

      require("telescope").setup({
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

  ---------------------------------------------------------------------------------------------------------------------------------------
  -- Tmux
  {
    "aserowy/tmux.nvim",
    config = function()
      return require("tmux").setup()
    end,
  },

  ---------------------------------------------------------------------------------------------------------------------------------------
  -- Comment.nvim
  {
    "numToStr/Comment.nvim",
    config = true,
  },

  ---------------------------------------------------------------------------------------------------------------------------------------
  -- Bufremove
  {
    "echasnovski/mini.bufremove",
    version = false,
    config = function()
      require("mini.bufremove").setup({
        symbol = "|",
      })
    end,
  },

  ---------------------------------------------------------------------------------------------------------------------------------------
  -- copilot
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    build = ":Copilot auth",
    opts = {
      panel = {
        enabled = false,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        keymap = {
          accept = "<M-l>",
          accept_word = false,
          accept_line = false,
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
    },
  },

  -------------------------------------------------------------------------------------------------------------------------------------
  -- gitsigns
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
    },
  },

  ----------------------------------------------------------------------------------------------------
  -- folding
  {
    "kevinhwang91/nvim-ufo",
    dependencies = {
      "kevinhwang91/promise-async" -- Thư viện cần thiết cho ufo.nvim
    },
    config = function()
      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

      require('ufo').setup({
        provider_selector = function(bufnr, filetype, buftype)
          return { 'treesitter', 'indent' }
        end
      })
    end
  }
}
