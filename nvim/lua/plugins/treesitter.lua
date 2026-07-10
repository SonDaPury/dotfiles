return {
  -- nvim-treesitter/nvim-treesitter: parser cú pháp, dùng cho highlight/indent chính xác hơn regex
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    dependencies = {
      -- nvim-treesitter/nvim-treesitter-textobjects: text object theo cú pháp (function, class, ...)
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua",
          "vim",
          "vimdoc",
          "query",
          "bash",
          "markdown",
          "markdown_inline",
          "json",
          "yaml",
          "javascript",
          "typescript",
          "tsx",
          "html",
          "css",
          "go",
          "cpp",
        },
        highlight = { enable = true },
        indent = { enable = true },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
        },
      })
    end,
  },
  -- windwp/nvim-ts-autotag: tự đóng/đổi tên tag khi sửa tag mở (HTML/JSX/TSX/Vue...)
  {
    "windwp/nvim-ts-autotag",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },
  -- HiPhish/rainbow-delimiters.nvim: tô màu cặp ngoặc () [] {} theo cấp độ lồng nhau
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "VeryLazy",
  },
  -- nvim-treesitter/nvim-treesitter-context: hiện function/class hiện tại khi cuộn xuống, tối đa 3 dòng
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      max_lines = 3,
    },
  },
}
