return {
	-- Neotree
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
			{
				"s1n7ax/nvim-window-picker",
				version = "2.*",
				config = function()
					require("window-picker").setup({
						filter_rules = {
							include_current_win = false,
							autoselect_one = true,
							bo = {
								filetype = { "neo-tree", "neo-tree-popup", "notify" },
								buftype = { "terminal", "quickfix" },
							},
						},
					})
				end,
			},
		},
		keys = {
			{ "<C-n>", "<cmd>Neotree toggle<CR>", desc = "Neotree Toggle" },
			{ "<leader>e", "<cmd>Neotree reveal<cr>", desc = "Neotree Reveal" },
		},
		config = function()
			-- Set icon for dianogstics
			vim.fn.sign_define("DiagnosticSignError", { text = " ", texthl = "DiagnosticSignError" })
			vim.fn.sign_define("DiagnosticSignWarn", { text = " ", texthl = "DiagnosticSignWarn" })
			vim.fn.sign_define("DiagnosticSignInfo", { text = " ", texthl = "DiagnosticSignInfo" })
			vim.fn.sign_define("DiagnosticSignHint", { text = "󰌵", texthl = "DiagnosticSignHint" })

			-- Setup neotree
			require("neo-tree").setup({
				close_if_last_window = true,
				filesystem = {
					filtered_items = {
						hide_dotfiles = false,
						hide_gitignored = false,
						hide_hidden = false,
					},
				},
			})
		end,
	},

	-- Lua line
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			require("lualine").setup()
		end,
	},

	-- Bufferline
	{
		"akinsho/bufferline.nvim",
		version = "*",
		opts = {
			options = {
				mode = "buffers",
				-- separator_style = "slant",
				themable = true,
				show_buffer_close_icons = false,
				diagnostics = "nvim_lsp",
				diagnostics_indicator = function(count, level, diagnostics_dict, context)
					local icon = level:match("error") and " " or ""
					return " " .. icon
				end,
				indicator = {
					style = "icon",
				},
				modified_icon = "●",
				close_icon = "",
				left_trunc_marker = "",
				right_trunc_marker = "",
				tab_size = 20,
				diagnostics_update_in_insert = true,
				-- icon = "▎", -- this should be omitted if indicator style is not 'icon'
			},
			highlights = {
				buffer_selected = {
					fg = "#c0e4eb",
					bold = true,
				},
				warning = {
					fg = "#d9ca00",
					sp = "#d9ca00",
					bg = "#27283d",
				},
				warning_visible = {
					fg = "#d9ca00",
					bg = "#27283d",
				},
				warning_selected = {
					fg = "#d9ca00",
					sp = "#d9ca00",
					bold = true,
					italic = true,
				},
				warning_diagnostic = {
					fg = "#d9ca00",
					sp = "#d9ca00",
					bg = "#27283d",
				},
				warning_diagnostic_visible = {
					fg = "#d9ca00",
					bg = "#27283d",
				},
				warning_diagnostic_selected = {
					fg = "#d9ca00",
					bold = true,
					italic = true,
				},
				error = {
					fg = "#cf1114",
					bg = "#27283d",
					sp = "#cf1114",
				},
				error_visible = {
					fg = "#cf1114",
					bg = "#27283d",
				},
				error_selected = {
					fg = "#cf1114",
					sp = "#cf1114",
					bold = true,
					italic = true,
				},
				error_diagnostic = {
					fg = "#cf1114",
					bg = "#27283d",
					sp = "#cf1114",
				},
				error_diagnostic_visible = {
					fg = "#cf1114",
					bg = "#27283d",
				},
				error_diagnostic_selected = {
					fg = "#cf1114",
					sp = "#cf1114",
					bold = true,
					italic = true,
				},
				hint = {
					bg = "#27283d",
				},
				hint_diagnostic = {
					bg = "#27283d",
				},
				info = {
					bg = "#27283d",
				},
				info_visible = {
					bg = "#27283d",
				},
				info_diagnostic = {
					bg = "#27283d",
				},
				info_diagnostic_visible = {
					bg = "#27283d",
				},

				background = {
					bg = "#27283d",
					fg = "#6d6e78",
				},
				fill = {
					bg = "#27283d",
				},
				separator = {
					bg = "#27283d",
				},
				separator_selected = {
					fg = "#3640f5",
					bg = "#3640f5",
				},
				indicator_selected = {
					fg = "#3366d6",
					-- bg = "#3640f5",
				},
			},
		},
	},

	-- Auto close tag
	{
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},

	-- Indent
	{
		"echasnovski/mini.indentscope",
		version = false,
		opts = {
			symbol = "▏",
			-- symbol = "│",
			-- symbol = "╎",
			options = { try_as_border = true },
		},
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		-- event = "LazyFile",
		opts = {
			indent = {
				char = "▏",
				tab_char = "▏",
			},
			scope = { enabled = false },
		},
		main = "ibl",
	},
	{
		"rcarriga/nvim-notify",
		config = function()
			vim.notify = require("notify")
			-- notify.setup()
		end,
	},

	-- Trouble nvim
	{
	  "folke/trouble.nvim",
	  opts = {
	    position = "bottom",
	    auto_open = false,
	    auto_close = false,
	    auto_preview = true,
	    height = 5,
	  },
	},

	-- Dressing
	{
		"stevearc/dressing.nvim",
		opts = {},
		config = function(_, opts)
			require("dressing").setup(opts)
		end,
	},
}
