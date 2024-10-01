return {
	-- {
	-- 	"ellisonleao/gruvbox.nvim",
	-- 	priority = 1000,
	-- 	opts = {
	-- 		bold = false,
	-- 		italic = {
	-- 			strings = false,
	-- 			emphasis = false,
	-- 			comments = false,
	-- 			operators = false,
	-- 			folds = false,
	-- 		},
	-- 	},
	-- 	config = function(_, opts)
	-- 		require("gruvbox").setup(opts)
	-- 		vim.cmd("colorscheme gruvbox")
	-- 	end,
	-- },
	-- {
	-- 	"craftzdog/solarized-osaka.nvim",
	-- 	lazy = false,
	-- 	priority = 1000,
	-- 	opts = {},
	-- 	config = function()
	-- 		vim.cmd([[colorscheme solarized-osaka]])
	-- 	end,
	-- },
	{
		"joshdick/onedark.vim",
		config = function()
			vim.cmd([[
      colorscheme onedark
      ]])
		end,
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"c_sharp",
				"lua",
				"vim",
				"vimdoc",
				"javascript",
				"typescript",
				"html",
				"json",
				"markdown",
				"markdown_inline",
				"java",
				"css",
				"cpp",
				"c",
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
