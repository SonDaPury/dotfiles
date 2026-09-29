return {
	-- folke/tokyonight.nvim
	{ "folke/tokyonight.nvim", lazy = true },
	-- catppuccin/nvim
	{ "catppuccin/nvim", name = "catppuccin", lazy = true },
	-- ellisonleao/gruvbox.nvim
	{ "ellisonleao/gruvbox.nvim", lazy = true },
	-- rebelot/kanagawa.nvim
	{ "rebelot/kanagawa.nvim", lazy = true },
	-- craftzdog/solarized-osaka.nvim
	{
		"craftzdog/solarized-osaka.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			on_colors = function(colors)
				-- colors.yellow200 = "#ffd84d"
			end,
			on_highlights = function(hl, c)
				-- Cấu hình cho nhóm được tìm thấy từ lệnh :Inspect
				-- hl["@variable.javascript"] = { fg = c.yellow200, } -- Dùng biến màu yellow đã sửa ở trên
				-- hl["String"] = { fg = "#00FF00", italic = true } -- Truyền trực tiếp mã màu hex
				-- hl["@variable"] = { fg = c.blue }
			end,
		},
	},
	-- navarasu/onedark.nvim
	{ "navarasu/onedark.nvim", lazy = true },
	-- scottmckendry/cyberdream.nvim
	{ "scottmckendry/cyberdream.nvim", lazy = true, opts = { transparent = true } },
	-- neanias/everforest-nvim
	{ "neanias/everforest-nvim", lazy = true },
	-- Mofiqul/dracula.nvim: theme mặc định khi mở nvim lần đầu, trước khi chọn qua picker
	{
		"Mofiqul/dracula.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"nyoom-engineering/oxocarbon.nvim",
		lazy = true,
		build = false,
	},
	{ "bluz71/vim-moonfly-colors", name = "moonfly", lazy = true },
	{ "jacoborus/tender.vim", lazy = true },
	{ "vague-theme/vague.nvim", lazy = true },
	{
		"AlexvZyl/nordic.nvim",
		lazy = true,
	},
	{ "bluz71/vim-nightfly-colors", lazy = true },
	{ "rmehri01/onenord.nvim", lazy = true },
	{ "Shatur/neovim-ayu", lazy = true },
	{
		"xero/miasma.nvim",
		lazy = true,
	},
	{
		"olivercederborg/poimandres.nvim",
		lazy = true,
	},
	{
		"ribru17/bamboo.nvim",
		lazy = true,
	},
	{
		"dgox16/oldworld.nvim",
		lazy = true,
	},
	{ "miikanissi/modus-themes.nvim", lazy = true },
	{
		"oxfist/night-owl.nvim",
		lazy = true, -- make sure we load this during startup if it is your main colorscheme
		opts = {
			-- transparent_background = true,
			bold = false,
		},
	},
	{ "NTBBloodbath/doom-one.nvim", lazy = true },

	-- zaldih/themery.nvim: picker chọn colorscheme, tự lưu lựa chọn và áp dụng lại cho các lần mở nvim sau
	{
		"zaldih/themery.nvim",
		lazy = false,
		keys = {
			{ "<leader>th", "<cmd>Themery<cr>", desc = "Theme Picker" },
		},
		opts = {
			themes = {
				"tokyonight",
				"catppuccin",
				"gruvbox",
				"kanagawa",
				"solarized-osaka",
				"dracula",
				"onedark",
				"cyberdream",
				{
					name = "everforest-soft",
					colorscheme = "everforest",
					before = [[require("everforest").setup({ background = "soft" })]],
				},
				{
					name = "everforest-medium",
					colorscheme = "everforest",
					before = [[require("everforest").setup({ background = "medium" })]],
				},
				{
					name = "everforest-hard",
					colorscheme = "everforest",
					before = [[require("everforest").setup({ background = "hard" })]],
				},
				"oxocarbon",
				"moonfly",
				"tender",
				"vague",
				"nordic",
				"nightfly",
				"onenord",
				{
					name = "ayu-mirage",
					colorscheme = "ayu",
					before = [[require("ayu").setup({ mirage = true})]],
				},
				{
					name = "ayu-dark",
					colorscheme = "ayu",
					before = [[require("ayu").setup({ mirage = false})]],
				},
				"miasma",
				"poimandres",
				"bamboo",
				"oldworld",
				"modus",
				"night-owl",
				"doom-one",
			},
			livePreview = true,
		},
	},

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
				"java",
			}
			require("nvim-treesitter").install(ensure_installed)

			-- filetype của Neovim không phải lúc nào cũng trùng tên parser
			vim.treesitter.language.register("bash", "sh")
			vim.treesitter.language.register("tsx", "typescriptreact")

			-- Tự động kích hoạt Treesitter highlight cho mọi buffer có parser
			local group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				callback = function(args)
					if vim.bo[args.buf].buftype ~= "" then
						return
					end
					pcall(vim.treesitter.start, args.buf)
				end,
			})

			-- Kích hoạt ngay cho buffer hiện tại nếu đã được mở trước đó
			local current_buf = vim.api.nvim_get_current_buf()
			if vim.bo[current_buf].buftype == "" then
				pcall(vim.treesitter.start, current_buf)
			end
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
