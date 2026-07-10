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
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {},
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
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
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
      { "<leader><", "<cmd>BufferLineMovePrev<cr>",  desc = "Move Buffer Left" },
      { "<leader>>", "<cmd>BufferLineMoveNext<cr>",  desc = "Move Buffer Right" },
      { "<S-h>",     "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>",     "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    },
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        separator_style =
        "slant", -- separator_style = "slant" | "slope" | "thick" | "thin" | { 'any', 'any' },
        always_show_bufferline = true

      },
    },
  },
}
