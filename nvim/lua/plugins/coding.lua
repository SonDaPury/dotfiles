return {
	-- Auto pair
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},

	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = { { "nvim-lua/plenary.nvim" } },
		keys = {
			{
				"<C-p>",
				"<cmd>Telescope find_files<cr>",
				desc = "find files within current working directory, respects .gitignore",
				mode = { "n", "i" },
			},
			{
				"<leader>fs",
				"<cmd>Telescope live_grep<cr>",
				desc = "find string in current working directory as you type",
			},
			{
				"<leader>fc",
				"<cmd>Telescope grep_string<cr>",
				desc = "find string under cursor in current working directory",
			},
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "list open buffers in current neovim instance" },
			{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "list available help tags" },
		},
		config = function()
			local telescopeConfig = require("telescope.config")
			local telescope = require("telescope")
			local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
			table.insert(vimgrep_arguments, "--hidden")
			table.insert(vimgrep_arguments, "--glob")
			table.insert(vimgrep_arguments, "!**/.git/*")

			require("telescope").setup({
				defaults = {
					vimgrep_arguments = vimgrep_arguments,
				},
				pickers = {
					find_files = {
						find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
					},
				},
				extensions = {},
			})
		end,
	},

	-- Tmux
	{
		"aserowy/tmux.nvim",
		config = function()
			return require("tmux").setup()
		end,
	},

	-- Comment.nvim
	{
		"numToStr/Comment.nvim",
		config = true,
	},

	-- Bufremove
	{
		"echasnovski/mini.bufremove",
		version = false,
		config = function()
			require("mini.bufremove").setup({
				symbol = "|",
			})
		end,
	},

	-- Trouble nvim
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			height = 8,
		},
		keys = {
			{
				"<leader>xx",
				"<cmd>TroubleToggle workspace_diagnostics<cr>",
				mode = { "n" },
				desc = "Toogle workspace diagnostics",
			},
		},
	},

	-- Copilot
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		build = ":Copilot auth",
		opts = {
			panel = { enabled = false },
			auto_refresh = true,
			suggestion = {
				enabled = false,
				auto_trigger = true,
			},
			filetypes = {
				markdown = true,
				help = true,
			},
		},
		config = function(_, opts)
			require("copilot").setup(opts)
		end,
	},

	-- {
	-- 	"zbirenbaum/copilot-cmp",
	-- 	config = function()
	-- 		require("copilot_cmp").setup()
	-- 	end,
	-- },
}
