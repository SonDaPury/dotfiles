return {
	-- saghen/blink.cmp: completion engine, cấp capabilities cho LSP
	{
		"saghen/blink.cmp",
		version = "*",
		-- rafamadriz/friendly-snippets: kho snippet VSCode-style (cl, rfc, imp,...) - blink.cmp tự nhận
		-- vì friendly_snippets = true là mặc định, chỉ cần plugin này có trên runtimepath
		dependencies = { "rafamadriz/friendly-snippets" },
		opts = {
			keymap = {
				preset = "enter", -- <CR> để chọn gợi ý, <C-space> để mở menu
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
			},
			sources = {
				-- Nguồn gợi ý hoàn tất mã
				default = { "lsp", "path", "snippets", "buffer" },

				providers = {
					snippets = {
						opts = {
							extended_filetypes = {
								jsp = { "html" },
							},
						},
					},
				},
			},
			-- Tùy chỉnh hiển thị menu gợi ý
			completion = {
				menu = {
					border = "rounded",
					draw = {
						columns = {
							{ "kind_icon" },
							{ "label", "label_description", gap = 1 },
							{ "kind" }, -- Cột bên phải: hiển thị loại (Function, Snippet, Variable,...)
						},
						components = {
							-- Hiển thị ô vuông có màu thật khi gợi ý Tailwind CSS hoặc mã màu
							kind_icon = {
								text = function(ctx)
									local icon = ctx.kind_icon
									if ctx.item.source_name == "LSP" then
										local has_color, highlight_colors = pcall(require, "nvim-highlight-colors")
										if has_color then
											local color_item = highlight_colors.format(ctx.item.documentation, { kind = ctx.kind })
											if color_item and color_item.abbr ~= "" then
												icon = color_item.abbr
											end
										end
									end
									return icon .. ctx.icon_gap
								end,
								highlight = function(ctx)
									local highlight = "BlinkCmpKind" .. ctx.kind
									if ctx.item.source_name == "LSP" then
										local has_color, highlight_colors = pcall(require, "nvim-highlight-colors")
										if has_color then
											local color_item = highlight_colors.format(ctx.item.documentation, { kind = ctx.kind })
											if color_item and color_item.abbr_hl_group then
												highlight = color_item.abbr_hl_group
											end
										end
									end
									return highlight
								end,
							},
						},
					},
				},
				documentation = {
					auto_show = true,
					window = { border = "rounded" },
				},
			},

			-- Hiển thị gợi ý tham số khi gõ hàm/method
			signature = {
				enabled = true,
				window = { border = "rounded" },
			},
		},
	},
	-- nvimdev/lspsaga.nvim: làm đẹp hover/rename/code action/diagnostic (peek definition, finder, menu có preview)
	{
		"nvimdev/lspsaga.nvim",
		event = "LspAttach",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			ui = {
				border = "rounded",
				devicon = true,
			},
			lightbulb = {
				enable = false, -- Tắt lightbulb theo yêu cầu
			},
			outline = {
				layout = "float",
			},
		},
		-- Chuyển toàn bộ keymap về options keys của lazy.nvim
		keys = {
			-- Điều hướng & Tìm kiếm
			{ "gd", "<cmd>Lspsaga goto_definition<CR>", desc = "LSP: Nhảy tới định nghĩa (Definition)" },
			{ "gp", "<cmd>Lspsaga peek_definition<CR>", desc = "LSP: Xem trước định nghĩa (Peek definition)" },
			{ "gr", "<cmd>Lspsaga finder<CR>", desc = "LSP: Tìm kiếm tham chiếu & định nghĩa (Finder)" },

			-- Tài liệu & Thao tác Code
			{ "K", "<cmd>Lspsaga hover_doc<CR>", desc = "LSP: Hiện tài liệu Hover" },
			{ "<leader>ca", "<cmd>Lspsaga code_action<CR>", mode = { "n", "v" }, desc = "LSP: Code Action" },
			{ "<leader>cr", "<cmd>Lspsaga rename<CR>", desc = "LSP: Đổi tên Symbol (Rename)" },

			-- Chẩn đoán lỗi (Diagnostics)
			{ "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", desc = "LSP: Nhảy tới lỗi trước" },
			{ "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", desc = "LSP: Nhảy tới lỗi sau" },
			{
				"<leader>cd",
				"<cmd>Lspsaga show_line_diagnostics<CR>",
				desc = "LSP: Xem chi tiết lỗi dòng hiện tại",
			},

			-- Cấu trúc code (Outline popup)
			{ "<leader>co", "<cmd>Lspsaga outline<CR>", desc = "LSP: Bật/Tắt cây cấu trúc code (Outline)" },
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
			-- require("config.lsp.keymaps")

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
