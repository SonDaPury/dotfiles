return {
  -- auto pair
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" },
        typescript = { "template_string" },
        java = false,
      },
    },
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

  -- multi cursor
  {
    "smoka7/multicursors.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvimtools/hydra.nvim",
    },
    opts = {},
    cmd = { "MCstart", "MCvisual", "MCclear", "MCpattern", "MCvisualPattern", "MCunderCursor" },
    keys = {
      {
        mode = { "v", "n" },
        "<Leader>m",
        "<cmd>MCstart<cr>",
        desc = "Create a selection for selected text or word under the cursor",
      },
    },
  },

  -- Auto close tag
  {
    "windwp/nvim-ts-autotag",
    ft = {
      "html",
      "javascriptreact", -- Dành cho file .js chứa JSX
      "typescriptreact", -- Dành cho file .tsx
      "vue",
      "xml",
      "php",
      "svelte",
    },
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },

  -- Improve comment in jsx tsx
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    opts = {},
  },

  -- Surrounding
  {
    "echasnovski/mini.surround",
    version = false,
    opts = {
      mappings = {
        add = "gsa",        -- Add surrounding in Normal and Visual modes
        delete = "gsd",     -- Delete surrounding
        find = "gsf",       -- Find surrounding (to the right)
        find_left = "gsF",  -- Find surrounding (to the left)
        highlight = "gsh",  -- Highlight surrounding
        replace = "gsr",    -- Replace surrounding
        update_n_lines = "gsn", -- Update `n_lines`

        suffix_last = "l",  -- Suffix to search with "prev" method
        suffix_next = "n",  -- Suffix to search with "next" method
      },
    },
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local builtin = require("telescope.builtin")

      telescope.setup({
        defaults = {
          layout_strategy = "vertical",
          layout_config = {
            vertical = {
              prompt_position = "top",
              preview_width = "55%",
              results_width = "45%",
            },
          },
          -- Keymap bên trong Telescope
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-s>"] = actions.select_horizontal, -- Mở trong split ngang
              ["<C-v>"] = actions.select_vertical, -- Mở trong split dọc
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            },
          },
        },
        pickers = {
          find_files = {
            -- Không hiển thị các file trong .git
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,             -- Bật fuzzy finding
            override_generic_sorter = true, -- Ghi đè sorter mặc định
            override_file_sorter = true, -- Ghi đè sorter file
            case_mode = "smart_case", -- "Smart" case sensitive
          },
        },
      })

      -- Tải extension fzf-native
      telescope.load_extension("fzf")

      local map = vim.keymap.set
      -- Tìm file
      map("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
      -- Tìm text trong toàn bộ project
      map("n", "<leader>fw", builtin.live_grep, { desc = "Live Grep" })
      -- Tìm các buffer đang mở
      map("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
      -- Tìm trong help tags
      map("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })

      -- Keymap cho LSP đã thảo luận
      map("n", "gd", builtin.lsp_definitions, { desc = "LSP Go to Definition" })
      -- map("n", "gr", builtin.lsp_references, { desc = "LSP Go to References" })
      map("n", "gI", builtin.lsp_implementations, { desc = "LSP Go to Implementation" })
    end,
  },

  -- rename
  {
    "smjonas/inc-rename.nvim",
    opts = {},
  },

  -- trouble
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      -- Tùy chỉnh của bạn ở đây
    },
    config = function(_, opts)
      require("trouble").setup(opts)
      local map = vim.keymap.set
      -- Mở/đóng panel Trouble
      map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Toggle Diagnostics (Trouble)" })
      -- Lọc theo workspace
      map(
        "n",
        "<leader>xW",
        "<cmd>Trouble diagnostics toggle filter.workspace=true<CR>",
        { desc = "Workspace Diagnostics (Trouble)" }
      )
    end,
  },

  -- folding
  {
    "kevinhwang91/nvim-ufo",
    dependencies = {
      "kevinhwang91/promise-async", -- Thư viện cần thiết cho ufo.nvim
    },
    config = function()
      vim.keymap.set("n", "zR", require("ufo").openAllFolds)
      vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

      require("ufo").setup({
        provider_selector = function(bufnr, filetype, buftype)
          return { "treesitter", "indent" }
        end,
      })
    end,
  },

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
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" },                    -- or zbirenbaum/copilot.lua
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken",                       -- Only on MacOS or Linux
    opts = {
      -- See Configuration section for options
    },
  },
}
