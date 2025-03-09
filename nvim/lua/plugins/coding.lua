return {
  -- colorscheme
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000, -- Ensure it loads first
  },
  {
    "craftzdog/solarized-osaka.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    "neanias/everforest-nvim",
    version = false,
    lazy = false,
    priority = 1000,
    config = function()
      require("everforest").setup({
        background = "hard",
      })
    end,
  },

  -- tmux
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
    },
  },

  -- disable ghost text in blink cmp
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        ghost_text = { enabled = false },
      },
    },
  },

  -- disable inlay hint
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
    },
  },

  -- enabled git blame
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        current_line_blame = true,
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        liquid = { "prettier" },
      },
    },
  },

  -- avante plugin
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
    opts = {
      -- add any opts here
      -- for example
      provider = "copilot",
      auto_suggestions_provider = "copilot",
      -- openai = {
      --   endpoint = "https://api.openai.com/v1",
      --   model = "gpt-4o", -- your desired model (or use gpt-4o, etc.)
      --   timeout = 30000, -- timeout in milliseconds
      --   temperature = 0, -- adjust if needed
      --   max_tokens = 4096,
      -- },
      copilot = {
        endpoint = "https://api.githubcopilot.com",
        model = "gpt-4o-2024-08-06",
        proxy = nil, -- [protocol://]host[:port] Use this proxy
        allow_insecure = false, -- Allow insecure server connections
        timeout = 30000, -- Timeout in milliseconds
        temperature = 0,
        max_tokens = 4096,
      },
    },
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "echasnovski/mini.pick", -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = true,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },

  -- hightlight color
  {
    "brenoprata10/nvim-highlight-colors",
    opts = {
      render = "virtual",
    },
  },
}
