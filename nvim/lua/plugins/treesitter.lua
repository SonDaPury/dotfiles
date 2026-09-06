return {
  -- nvim-treesitter/nvim-treesitter: parser cú pháp, dùng cho highlight/indent chính xác hơn regex
  -- Dùng branch "main" (bản viết lại mới) vì branch "master" đã bị đóng băng (chỉ giữ để
  -- tương thích ngược) và không nhận bản vá cho các thay đổi treesitter-core gần đây của
  -- Neovim — đó là nguyên nhân treesitter-context bị crash trên Neovim 0.12+.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ensure_installed = {
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
      }
      require("nvim-treesitter").install(ensure_installed)

      -- filetype của Neovim không phải lúc nào cũng trùng tên parser
      vim.treesitter.language.register("bash", "sh")
      vim.treesitter.language.register("tsx", "typescriptreact")

      local filetypes = {
        "lua",
        "vim",
        "help", -- vimdoc
        "query",
        "sh", -- bash
        "markdown",
        "json",
        "yaml",
        "javascript",
        "typescript",
        "typescriptreact", -- tsx
        "html",
        "css",
        "go",
        "cpp",
      }

      vim.api.nvim_create_autocmd("FileType", {
        pattern = filetypes,
        callback = function()
          -- pcall vì buffer có thể mở trước khi parser cài xong ở lần chạy đầu tiên
          pcall(vim.treesitter.start)
          vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo[0][0].foldmethod = "expr"
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  -- nvim-treesitter/nvim-treesitter-textobjects: text object theo cú pháp (function, class, ...)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
        },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local keymaps = {
        af = "@function.outer",
        ["if"] = "@function.inner",
        ac = "@class.outer",
        ic = "@class.inner",
      }
      for lhs, query in pairs(keymaps) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          select.select_textobject(query, "textobjects")
        end)
      end
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
