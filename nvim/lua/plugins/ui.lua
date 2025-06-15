return {
  -- Theme
  {
    "craftzdog/solarized-osaka.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      vim.cmd([[colorscheme solarized-osaka]])
    end,
  },

  -- Tree sitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = {
          "lua",
          "vim",
          "javascript",
          "typescript",
          "python",
          "html",
          "css",
          "json",
          "bash",
          "markdown",
          "angular",
          "scss",
          "tsx",
          "xml",
          "yaml",
        },

        -- Tự động cài đặt parser cho ngôn ngữ mới khi bạn mở file
        auto_install = true,

        -- Cho phép Neovim tiếp tục chạy trong khi parser được cài đặt ở dưới nền
        sync_install = true,

        -- Bật module tô màu cú pháp (quan trọng nhất!)
        highlight = {
          enable = true,
          -- Một vài file quá lớn có thể làm chậm, ta có thể tắt treesitter cho chúng
          disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
          -- Forcibly use fallback highlighting when treesitter parsing is slow
          additional_vim_regex_highlighting = false,
        },

        -- Bật module thụt lề (indentation)
        indent = { enable = true },
      })
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local lualine = require("lualine")

      -- Color table for highlights
      -- stylua: ignore
      local colors = {
        bg       = '#202328',
        fg       = '#bbc2cf',
        yellow   = '#ECBE7B',
        cyan     = '#008080',
        darkblue = '#081633',
        green    = '#98be65',
        orange   = '#FF8800',
        violet   = '#a9a1e1',
        magenta  = '#c678dd',
        blue     = '#51afef',
        red      = '#ec5f67',
      }

      local conditions = {
        buffer_not_empty = function()
          return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
        end,
        hide_in_width = function()
          return vim.fn.winwidth(0) > 80
        end,
        check_git_workspace = function()
          local filepath = vim.fn.expand("%:p:h")
          local gitdir = vim.fn.finddir(".git", filepath .. ";")
          return gitdir and #gitdir > 0 and #gitdir < #filepath
        end,
      }

      -- Config
      local config = {
        options = {
          -- Disable sections and component separators
          component_separators = "",
          section_separators = "",
          theme = {
            -- We are going to use lualine_c an lualine_x as left and
            -- right section. Both are highlighted by c theme .  So we
            -- are just setting default looks o statusline
            normal = { c = { fg = colors.fg, bg = colors.bg } },
            inactive = { c = { fg = colors.fg, bg = colors.bg } },
          },
        },
        sections = {
          -- these are to remove the defaults
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          -- These will be filled later
          lualine_c = {},
          lualine_x = {},
        },
        inactive_sections = {
          -- these are to remove the defaults
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          lualine_c = {},
          lualine_x = {},
        },
      }

      -- Inserts a component in lualine_c at left section
      local function ins_left(component)
        table.insert(config.sections.lualine_c, component)
      end

      -- Inserts a component in lualine_x at right section
      local function ins_right(component)
        table.insert(config.sections.lualine_x, component)
      end

      ins_left({
        function()
          return "▊"
        end,
        color = { fg = colors.blue },  -- Sets highlighting of component
        padding = { left = 0, right = 1 }, -- We don't need space before this
      })

      ins_left({
        -- mode component
        function()
          return ""
        end,
        color = function()
          -- auto change color according to neovims mode
          local mode_color = {
            n = colors.red,
            i = colors.green,
            v = colors.blue,
            [""] = colors.blue,
            V = colors.blue,
            c = colors.magenta,
            no = colors.red,
            s = colors.orange,
            S = colors.orange,
            [""] = colors.orange,
            ic = colors.yellow,
            R = colors.violet,
            Rv = colors.violet,
            cv = colors.red,
            ce = colors.red,
            r = colors.cyan,
            rm = colors.cyan,
            ["r?"] = colors.cyan,
            ["!"] = colors.red,
            t = colors.red,
          }
          return { fg = mode_color[vim.fn.mode()] }
        end,
        padding = { right = 1 },
      })

      ins_left({
        -- filesize component
        "filesize",
        cond = conditions.buffer_not_empty,
      })

      ins_left({
        "filename",
        cond = conditions.buffer_not_empty,
        color = { fg = colors.magenta, gui = "bold" },
      })

      ins_left({ "location" })

      ins_left({ "progress", color = { fg = colors.fg, gui = "bold" } })

      ins_left({
        "diagnostics",
        sources = { "nvim_diagnostic" },
        symbols = { error = " ", warn = " ", info = " " },
        diagnostics_color = {
          error = { fg = colors.red },
          warn = { fg = colors.yellow },
          info = { fg = colors.cyan },
        },
      })

      -- Insert mid section. You can make any number of sections in neovim :)
      -- for lualine it's any number greater then 2
      ins_left({
        function()
          return "%="
        end,
      })

      ins_left({
        -- Lsp server name .
        function()
          local msg = "No Active Lsp"
          local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
          local clients = vim.lsp.get_clients()
          if next(clients) == nil then
            return msg
          end
          for _, client in ipairs(clients) do
            local filetypes = client.config.filetypes
            if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
              return client.name
            end
          end
          return msg
        end,
        icon = " LSP:",
        color = { fg = "#ffffff", gui = "bold" },
      })

      -- Add components to right sections
      ins_right({
        "o:encoding",   -- option component same as &encoding in viml
        fmt = string.upper, -- I'm not sure why it's upper case either ;)
        cond = conditions.hide_in_width,
        color = { fg = colors.green, gui = "bold" },
      })

      ins_right({
        "fileformat",
        fmt = string.upper,
        icons_enabled = false, -- I think icons are cool but Eviline doesn't have them. sigh
        color = { fg = colors.green, gui = "bold" },
      })

      ins_right({
        "branch",
        icon = "",
        color = { fg = colors.violet, gui = "bold" },
      })

      ins_right({
        "diff",
        -- Is it me or the symbol for modified us really weird
        symbols = { added = " ", modified = "󰝤 ", removed = " " },
        diff_color = {
          added = { fg = colors.green },
          modified = { fg = colors.orange },
          removed = { fg = colors.red },
        },
        cond = conditions.hide_in_width,
      })

      ins_right({
        function()
          return "▊"
        end,
        color = { fg = colors.blue },
        padding = { left = 1 },
      })

      -- Now don't forget to initialize lualine
      lualine.setup(config)
    end,
  },

  -- neotree
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    lazy = false,
    keys = {
      { "<leader>e", ":Neotree toggle<cr>", mode = "n", silent = true, desc = "Toggle neotree" },
      { "<leader>E", ":Neotree reveal<cr>", mode = "n", silent = true, desc = "Toggle neotree reveal" },
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      filesystem = {
        -- follow_current_file = true,
        filtered_items = {
          visible = false,
          hide_dotfiles = false, -- hiện các file ẩn (dotfiles)
          hide_gitignored = false, -- ẩn các file trong .gitignore
          hide_hidden = false, -- không ẩn các file/thư mục hệ thống
          never_show = {
            ".DS_Store",
            "thumbs.db",
          },
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true, -- BẮT BUỘC để hiện icon expand/collapse
          expander_collapsed = "",
          expander_expanded = "",
          expander_highlight = "NeoTreeExpander",
        },
        icon = {
          folder_closed = "", -- Icon folder đóng
          folder_open = "", -- Icon folder mở
          folder_empty = "", -- Icon folder rỗng
        },
      },
    },
  },
  {
    "romgrk/barbar.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- BẮT BUỘC, để hiển thị icon
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    event = "VimEnter",
    keys = {
      { "<S-l>",      ":BufferNext<CR>",         mode = "n", desc = "Next Buffer",    silent = true },
      { "<S-h>",      ":BufferPrevious<CR>",     mode = "n", desc = "Prev Buffer",    silent = true },
      { "<leader>bd", ":BufferClose<CR>",        mode = "n", desc = "Close Buffer",   silent = true },
      { "<b",         ":BufferMovePrevious<CR>", mode = "n", desc = "Move Buffer -1", silent = true },
      { ">b",         ":BufferMoveNext<CR>",     mode = "n", desc = "Move Buffer +1", silent = true },
    },
    opts = {
      -- Bật/tắt animation
      animation = true,

      -- Tự động ẩn barbar khi chỉ có 1 buffer
      auto_hide = false,

      -- Bật/tắt icon đóng buffer
      closable = true,

      -- Icon để đóng buffer
      close_icon = "", -- Cần Nerd Font

      -- Highlight buffer hiện tại với màu in đậm
      highlight_visible = true,

      icons = {
        -- Hiển thị số thứ tự của buffer
        buffer_index = false,
        -- Icon ở cuối dòng, để false cho gọn
        separator_at_end = false,
        diagnostics = {
          [vim.diagnostic.severity.ERROR] = { enabled = true, icon = "⛔" },
          [vim.diagnostic.severity.WARN] = { enabled = true, icon = "⚠️" },
          [vim.diagnostic.severity.INFO] = { enabled = true },
          [vim.diagnostic.severity.HINT] = { enabled = true },
        },
        gitsigns = {
          added = { enabled = true, icon = "+" },
          changed = { enabled = true, icon = "~" },
          deleted = { enabled = true, icon = "-" },
        },
      },

      -- Tích hợp với các tab page gốc của Vim
      tabpages = true,

      -- Cho phép click chuột
      clickable = true,
    },
  },

  -- nvim highlight color
  {
    "brenoprata10/nvim-highlight-colors",
    opts = {
      render = "virtual",
      enable_tailwind = true,
    },
  },

  -- enabled git blame
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        current_line_blame = true,
        signs = {
          add = { text = "┃" },
          change = { text = "┃" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signs_staged = {
          add = { text = "┃" },
          change = { text = "┃" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signs_staged_enable = true,
        signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
        numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
        linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
        word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
        watch_gitdir = {
          follow_files = true,
        },
        auto_attach = true,
      })
    end,
  },

  -- indent
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "VeryLazy",
    -- event = "LazyFile",
    opts = {
      indent = {
        char = "┆",
        tab_char = "┆",
      },
      scope = { enabled = false },
    },
    main = "ibl",
  },
  {
    "echasnovski/mini.indentscope",
    version = "*",
    event = "VeryLazy",
    opts = {
      draw = {
        -- '┆' là một lựa chọn rất đẹp cho nét đứt.
        -- Các lựa chọn khác: '│' (nét liền), '¦' (nét đứt thưa)
        symbol = "┆",
      },
      options = {
        try_as_border = true,
      },
    },
  },

  -- Notify
  --   {
  --   'rcarriga/nvim-notify',
  --   config = function()
  --     local notify = require('notify')
  --     vim.notify = notify
  --
  --     notify.setup({
  --       stages = 'fade_in_slide_out',
  --       top_down = true,
  --       timeout = 3000,
  --       background_colour = 'NotifyBackground',
  --     })
  --   end,
  -- },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      lsp_progress = {
        enabled = true,
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        -- long_message_to_split = true,
        inc_rename = true,
      },
    },
  },

  -- nvim treesitter context
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    opts = {
      max_lines = 3,
      min_window_height = 10,
    },
  },

  -- Plugin tạo breadcrumb
  {
    "fgheng/winbar.nvim",
    opts = {
      enabled = true,
      show_file_path = true,
      show_symbols = true,
    },
  },

  -- Outline
  {
    "hedyhli/outline.nvim",
    lazy = true,
    cmd = { "Outline", "OutlineOpen" },
    keys = {
      { "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
    },
    opts = {
      position = "left",
      wrap = true,
    },
  },

  -- Which key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
}
