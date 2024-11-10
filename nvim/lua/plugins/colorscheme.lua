return {
  -- colorschemes
  {
    "craftzdog/solarized-osaka.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd [[colorscheme solarized-osaka]]
    end
  },

  -- treesitter
  -- {
  --   'nvim-treesitter/nvim-treesitter',
  --   build = ":TSUpdate",
  --   lazy = vim.fn.argc(-1) == 0,
  --   cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
  --   opts = {
  --     ensure_installed = { "lua", "javascript", "typescript", "bash", "css", "json", "vim", "nginx", "scss", "sql", "tsx" },
  --     sync_install = true,
  --     auto_install = true,
  --     highlight = {
  --       enable = true
  --     },
  --     indent = {
  --       enable = true,
  --     },
  --     autotag = {
  --       enable = true,
  --     },
  --     context_commentstring = {
  --       enable = true,
  --       enable_autocmd = false,
  --     },
  --   }
  -- }
  {
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"lua",
				"vim",
				"vimdoc",
				"javascript",
				"typescript",
				"html",
				"json",
				"markdown",
				"markdown_inline",
				"css",
        "tsx",
        "sql",
        "scss",
        "bash",
        "nginx",
			},
			auto_install = true,
			highlight = {
				enable = true,
			},
			indent = {
				enable = true,
			},
			autotag = {
				enable = true,
			},
			context_commentstring = {
				enable = true,
				enable_autocmd = false,
			},
		},
		event = { "BufReadPost", "BufNewFile" },
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
			parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }
		end,
	},
}
