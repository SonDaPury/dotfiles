return {
	---------------------------------------------------------
	-- indent line
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		opts = {
			indent = {
				char = "¦", -- Đổi ký tự vạch đứt ở đây
				tab_char = "¦",
			},
			scope = { enabled = false }, -- Tắt vạch sáng scope nếu bạn dùng chung với mini.indentscope
		},
	},

	{ "nvim-mini/mini.indentscope", version = false, opts = {} },

	---------------------------------------------------------
	-- Status line
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			theme = "auto",
		},
	},

	---------------------------------------------------------
	-- Bufferline: Quản lý và hiển thị danh sách tab/buffer
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		keys = {
			{ "<S-h>", "<cmd>BufferLineCyclePrev<CR>", desc = "Buffer trước (Trái)" },
			{ "<S-l>", "<cmd>BufferLineCycleNext<CR>", desc = "Buffer tiếp theo (Phải)" },
			{ "[b", "<cmd>BufferLineCyclePrev<CR>", desc = "Buffer trước (Trái)" },
			{ "]b", "<cmd>BufferLineCycleNext<CR>", desc = "Buffer tiếp theo (Phải)" },
			{ "[B", "<cmd>BufferLineMovePrev<CR>", desc = "Di chuyển buffer sang trái" },
			{ "]B", "<cmd>BufferLineMoveNext<CR>", desc = "Di chuyển buffer sang phải" },
			{ "<leader>bp", "<cmd>BufferLineTogglePin<CR>", desc = "Ghim/Bỏ ghim buffer" },
			{ "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", desc = "Đóng các buffer khác" },
			{ "<leader>br", "<cmd>BufferLineCloseRight<CR>", desc = "Đóng buffer bên phải" },
			{ "<leader>bl", "<cmd>BufferLineCloseLeft<CR>", desc = "Đóng buffer bên trái" },
		},
		opts = {
			options = {
				close_command = function(n)
					pcall(require("mini.bufremove").delete, n, false)
				end,
				right_mouse_command = function(n)
					pcall(require("mini.bufremove").delete, n, false)
				end,
				diagnostics = "nvim_lsp",
				always_show_bufferline = true,
				diagnostics_indicator = function(_, _, diag)
					local icons = { Error = "✘ ", Warn = "▲ ", Hint = "⚑ ", Info = "ℹ " }
					local ret = (diag.error and icons.Error .. diag.error .. " " or "")
						.. (diag.warning and icons.Warn .. diag.warning or "")
					return vim.trim(ret)
				end,
				offsets = {
					{
						filetype = "neo-tree",
						text = "Neo-tree",
						highlight = "Directory",
						text_align = "left",
					},
				},
			},
		},
	},

	---------------------------------------------------------
	-- nvim-notify: Popup thông báo nổi góc trên bên phải
	{
		"rcarriga/nvim-notify",
		opts = {
			timeout = 3000,
			stages = "fade_in_slide_out",
			render = "default",
			background_colour = "#000000",
			max_width = 50,
		},
		init = function()
			vim.notify = require("notify")
		end,
	},

	---------------------------------------------------------
	-- fidget.nvim: Tiến trình LSP loading dạng spinner góc dưới
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {
			progress = {
				display = {
					render_limit = 16,
					done_icon = "✔",
				},
			},
			notification = {
				window = {
					winblend = 0,
					border = "rounded",
				},
			},
		},
	},
}
