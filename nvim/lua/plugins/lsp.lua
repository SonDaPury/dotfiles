return {
  -- saghen/blink.cmp: completion engine, cấp capabilities cho LSP
  {
    "saghen/blink.cmp",
    version = "*",
    -- rafamadriz/friendly-snippets: kho snippet VSCode-style (cl, rfc, imp,...) - blink.cmp tự nhận
    -- vì friendly_snippets = true là mặc định, chỉ cần plugin này có trên runtimepath
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "enter" },
    },
  },
  -- nvimdev/lspsaga.nvim: làm đẹp hover/rename/code action/diagnostic (peek definition, finder, menu có preview)
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      ui = {
        code_action = ''
      }
    },
  },
  -- rachartier/tiny-inline-diagnostic.nvim: làm đẹp virtual text diagnostic (box gọn, icon rõ)
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    opts = {},
  },
  -- mason-org/mason.nvim + mason-org/mason-lspconfig.nvim + neovim/nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("config.lsp.keymaps")

      -- tiny-inline-diagnostic.nvim tự vẽ virtual text đẹp hơn, tắt virtual_text mặc định để tránh trùng
      vim.diagnostic.config({ virtual_text = false })

      local servers = require("config.lsp.servers")

      for name, opts in pairs(servers) do
        opts.capabilities = require("blink.cmp").get_lsp_capabilities(opts.capabilities)
        vim.lsp.config(name, opts)
      end

      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
      })
    end,
  },
}
