return {
  -- nvim-lualine/lualine.nvim: statusline hiển thị mode, git branch, diagnostics, filetype
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {},
  },
  -- nvim-mini/mini.bufremove: xóa buffer mà không phá layout cửa sổ (tránh sidebar như neo-tree chiếm hết màn hình)
  {
    "nvim-mini/mini.bufremove",
    version = false,
  },
  -- folke/which-key.nvim: hiện popup gợi ý keymap khi gõ <leader>, tự đọc desc từ mọi keymap đã khai báo
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
  -- lukas-reineke/indent-blankline.nvim: hiện đường kẻ thụt lề (indent guide)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      scope = { enabled = false },
    },
  },
  -- nvim-mini/mini.indentscope: vẽ đường thẳng đứng đánh dấu phạm vi thụt lề (scope) chứa con trỏ hiện tại
  {
    "nvim-mini/mini.indentscope",
    version = false,
    event = { "BufReadPre", "BufNewFile" },
    init = function()
      -- đăng ký sớm ở init() (chạy ngay lúc khởi động, không chờ lazy-load event) vì neo-tree
      -- set filetype qua API buffer trực tiếp (không qua :edit) nên có thể fire trước khi
      -- plugin này lazy-load; đăng ký muộn (trong config()) sẽ bỏ lỡ lần fire đó
      vim.api.nvim_create_autocmd("FileType", {
        desc = "Tắt mini.indentscope ở các filetype UI phụ",
        pattern = { "neo-tree", "help", "man", "lazy", "mason", "checkhealth", "notify", "trouble", "lspinfo", "qf", "startuptime" },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
    config = function()
      require("mini.indentscope").setup({
        draw = {
          animation = require("mini.indentscope").gen_animation.none(), -- hiện ngay, không animation
        },
      })
    end,
  },
  -- NvChad/nvim-colorizer.lua: hiện màu của mã màu (hex/rgb/...) ngay trong buffer dưới dạng ô vuông virtual text
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      user_default_options = {
        mode = "virtualtext",
        virtualtext = "■",
      },
    },
  },
  -- Bekaboo/dropbar.nvim: winbar breadcrumb kiểu VSCode (đường dẫn file + function/class hiện tại), click để nhảy
  {
    "Bekaboo/dropbar.nvim",
    dependencies = { "nvim-telescope/telescope-fzf-native.nvim" },
    opts = {},
  },
  -- folke/noice.nvim: làm đẹp cmdline/message/popupmenu, kèm rcarriga/nvim-notify cho notification
  -- {
  --   "folke/noice.nvim",
  --   event = "VeryLazy",
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "rcarriga/nvim-notify",
  --   },
  --   opts = {},
  -- },
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.routes = opts.routes or {}
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      })
      local focused = true
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function()
          focused = true
        end,
      })
      vim.api.nvim_create_autocmd("FocusLost", {
        callback = function()
          focused = false
        end,
      })
      table.insert(opts.routes, 1, {
        filter = {
          cond = function()
            return not focused
          end,
        },
        view = "notify_send",
        opts = { stop = false },
      })

      opts.commands = {
        all = {
          -- options for the message history that you get with `:Noice`
          view = "split",
          opts = { enter = true, format = "details" },
          filter = {},
        },
      }

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(event)
          vim.schedule(function()
            require("noice.text.markdown").keys(event.buf)
          end)
        end,
      })

      opts.presets = opts.presets or {}
      opts.presets.lsp_doc_border = true
    end,
  },

  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 5000,
    },
  },


  -- j-hui/fidget.nvim: hiện tiến trình LSP (indexing/loading...) ở góc phải dưới
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {},
  },
  -- folke/trouble.nvim: panel đẹp cho diagnostics/quickfix/references
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",              desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    },
    opts = {},
  },
  -- akinsho/bufferline.nvim: hiển thị danh sách buffer đang mở dạng tab, kèm diagnostic LSP
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    keys = {
      {
        "<leader>bd",
        function()
          require("mini.bufremove").delete(0, false)
        end,
        desc = "Close Buffer",
      },
      {
        "<leader>bD",
        function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].buflisted then
              require("mini.bufremove").delete(buf, false)
            end
          end
        end,
        desc = "Close All Buffers",
      },
      {
        "<leader>bo",
        function()
          local current = vim.api.nvim_get_current_buf()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].buflisted and buf ~= current then
              require("mini.bufremove").delete(buf, false)
            end
          end
        end,
        desc = "Close Other Buffers",
      },
      { "<leader><", "<cmd>BufferLineMovePrev<cr>",  desc = "Move Buffer Left" },
      { "<leader>>", "<cmd>BufferLineMoveNext<cr>",  desc = "Move Buffer Right" },
      { "<S-h>",     "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>",     "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    },
    opts = function()
      local yellow = "#ffd84d" -- Màu nền vàng cho active tab
      local white = "#ffffff"  -- Màu chữ trắng cho active tab

      local function get_hl_hex(name, attr)
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        if hl and hl[attr] then
          return string.format("#%06x", hl[attr])
        end
        return nil
      end

      return {
        options = {
          diagnostics = "nvim_lsp",
          separator_style = "slant",
          always_show_bufferline = true,
          themable = false, -- Tránh bị colorscheme ghi đè highlight tùy chỉnh
        },
        highlights = function(defaults)
          -- Lấy màu nền của bar (fill). Nếu theme bật transparent (như solarized-osaka),
          -- bg sẽ là NONE khiến glyph tam giác slant bị terminal vẽ thành màu trắng.
          -- Vì vậy cần fallback về màu nền thực tế (TabLineFill, StatusLine hoặc Normal)
          local fill_bg = defaults.highlights.fill and defaults.highlights.fill.bg
          if not fill_bg or fill_bg == "NONE" then
            fill_bg = get_hl_hex("TabLineFill", "bg")
              or get_hl_hex("StatusLine", "bg")
              or get_hl_hex("Normal", "bg")
              or "#16181c"
          end

          local inactive_bg = defaults.highlights.background and defaults.highlights.background.bg
          if not inactive_bg or inactive_bg == "NONE" then
            inactive_bg = get_hl_hex("TabLine", "bg")
              or get_hl_hex("StatusLineNC", "bg")
              or fill_bg
          end

          return {
            fill = {
              bg = fill_bg,
            },
            background = {
              bg = inactive_bg,
            },
            -- Tab đang active: màu vàng back và chữ trắng
            buffer_selected = {
              fg = white,
              bg = yellow,
              bold = true,
              italic = false,
            },
            -- Separator slant cho active tab: fg là màu nền fill (khoét góc), bg là màu tab vàng
            separator_selected = {
              fg = fill_bg,
              bg = yellow,
            },
            -- Separator cho các tab bình thường
            separator = {
              fg = fill_bg,
              bg = inactive_bg,
            },
            separator_visible = {
              fg = fill_bg,
              bg = inactive_bg,
            },
            -- Các thành phần phụ trong tab active đồng bộ nền vàng và chữ trắng
            close_button_selected = {
              fg = white,
              bg = yellow,
            },
            duplicate_selected = {
              fg = white,
              bg = yellow,
            },
            modified_selected = {
              fg = white,
              bg = yellow,
            },
            numbers_selected = {
              fg = white,
              bg = yellow,
            },
            indicator_selected = {
              fg = yellow,
              bg = yellow,
            },
            diagnostic_selected = {
              fg = white,
              bg = yellow,
            },
            info_selected = {
              fg = white,
              bg = yellow,
            },
            info_diagnostic_selected = {
              fg = white,
              bg = yellow,
            },
            warning_selected = {
              fg = white,
              bg = yellow,
            },
            warning_diagnostic_selected = {
              fg = white,
              bg = yellow,
            },
            error_selected = {
              fg = white,
              bg = yellow,
            },
            error_diagnostic_selected = {
              fg = white,
              bg = yellow,
            },
            hint_selected = {
              fg = white,
              bg = yellow,
            },
            hint_diagnostic_selected = {
              fg = white,
              bg = yellow,
            },
          }
        end,
      }
    end,
  },
}
