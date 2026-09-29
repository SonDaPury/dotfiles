return {
	-- Tmux nvigation
	{
		"christoomey/vim-tmux-navigator",
		lazy = false,
	},

	---------------------------------------------------------------------
	-- windwp/nvim-autopairs: tự động đóng ngoặc/dấu ngoặc kép khi gõ
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},

	---------------------------------------------------------------------
	-- Icons
	{
		"nvim-mini/mini.icons",
		version = false,
		init = function()
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
	},

	---------------------------------------------------------------------
	-- mở rộng phần comment
	{
		"nvim-mini/mini.comment",
		version = false,
		opts = {},
		config = function()
			require("mini.comment").setup()
		end,
	},
	{
		"folke/ts-comments.nvim",
		opts = {},
		event = "VeryLazy",
		enabled = vim.fn.has("nvim-0.10.0") == 1,
	},

	---------------------------------------------------------------------
	-- Move words
	{
		"nvim-mini/mini.move",
		version = false,
		opts = {},
		config = function()
			require("mini.move").setup()
		end,
	},

	---------------------------------------------------------------------
	-- Surrounding
	{
		"nvim-mini/mini.surround",
		version = false,
		opts = {},
	},

	---------------------------------------------------------------------
	-- Xóa Buffer
	{
		"nvim-mini/mini.bufremove",
		version = false,
		keys = {
			{
				"<leader>bd",
				function()
					require("mini.bufremove").delete(0, false)
				end,
				"n",
				{ desc = "Đóng buffer giữ nguyên layout" },
			},
		},
	},

	---------------------------------------------------------------------
	-- Hiển thị keymaps
	{
		"nvim-mini/mini.clue",
		version = false,
		opts = function()
			local miniclue = require("mini.clue")
			return {
				-- 1. TRIGGERS: Khai báo những phím sẽ kích hoạt popup gợi ý
				triggers = {
					-- Phím Leader
					{ mode = "n", keys = "<Leader>" },
					{ mode = "x", keys = "<Leader>" },

					-- Các nhóm phím mặc định của Vim
					{ mode = "n", keys = "g" },
					{ mode = "x", keys = "g" },
					{ mode = "n", keys = "z" },
					{ mode = "x", keys = "z" },
					{ mode = "n", keys = "]" },
					{ mode = "x", keys = "]" },
					{ mode = "n", keys = "[" },
					{ mode = "x", keys = "[" },
					{ mode = "n", keys = "<C-w>" },
					{ mode = "n", keys = "'" },
					{ mode = "n", keys = "`" },
					{ mode = "x", keys = "'" },
					{ mode = "x", keys = "`" },
					{ mode = "n", keys = '"' },
					{ mode = "x", keys = '"' },
					{ mode = "i", keys = "<C-r>" },
					{ mode = "c", keys = "<C-r>" },
				},

				-- 2. CLUES: Cung cấp nội dung hiển thị trong popup
				clues = {
					miniclue.gen_clues.square_brackets(),
					miniclue.gen_clues.builtin_completion(),
					miniclue.gen_clues.g(),
					miniclue.gen_clues.marks(),
					miniclue.gen_clues.registers(),
					miniclue.gen_clues.windows(),
					miniclue.gen_clues.z(),

					-- Nhóm phím tùy chỉnh
					{ mode = "n", keys = "<Leader>f", desc = "+Find (Tìm kiếm)" },
					{ mode = "n", keys = "<Leader>g", desc = "+Git (GitUI/Octo)" },
					{ mode = "n", keys = "<Leader>b", desc = "+Buffer" },
					{ mode = "n", keys = "<Leader>c", desc = "+Code/LSP" },
				},

				-- 3. WINDOW: Giao diện popup
				window = {
					delay = 300,
					config = {
						width = "auto",
						border = "rounded",
					},
				},
			}
		end,
	},

	---------------------------------------------------------------------
	-- Telescope: Tìm kiếm file, text, emoji
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			"xiyaowong/telescope-emoji.nvim",
		},
		keys = {
			{
				"<leader>ff",
				function()
					require("telescope.builtin").find_files()
				end,
				desc = "Tìm file trong dự án",
			},
			{
				"<leader>fF",
				function()
					require("telescope.builtin").find_files({ hidden = true, no_ignore = true })
				end,
				desc = "Tìm file (kèm hidden & dotfile)",
			},
			{
				"<leader>fw",
				function()
					require("telescope.builtin").live_grep()
				end,
				desc = "Tìm từ khóa (Live grep)",
			},
			{
				"<leader>fe",
				"<cmd>Telescope emoji<CR>",
				desc = "Chọn Emoji",
			},
		},
		opts = function()
			local actions = require("telescope.actions")
			return {
				defaults = {
					prompt_prefix = "  ",
					selection_caret = "  ",
					border = true,
					borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
					mappings = {
						i = {
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
							["<C-c>"] = actions.close,
							["<Esc>"] = actions.close,
						},
					},
				},
			}
		end,
		config = function(_, opts)
			local telescope = require("telescope")
			telescope.setup(opts)
			pcall(telescope.load_extension, "fzf")
			pcall(telescope.load_extension, "emoji")
		end,
	},

	---------------------------------------------------------------------
	-- nvim-neo-tree/neo-tree.nvim: Cây thư mục (File Explorer Sidebar)
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd = "Neotree",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{
				"<leader>e",
				"<cmd>Neotree toggle left<CR>",
				desc = "Bật/Tắt cây thư mục (Neo-tree)",
			},
			{
				"<leader>ge",
				"<cmd>Neotree git_status left<CR>",
				desc = "Neo-tree: Xem trạng thái Git",
			},
			{
				"<leader>be",
				"<cmd>Neotree buffers left<CR>",
				desc = "Neo-tree: Xem danh sách Buffer",
			},
		},
		deactivate = function()
			vim.cmd("Neotree close")
		end,
		init = function()
			-- Tự động mở Neo-tree nếu khởi động Neovim từ một thư mục (ví dụ `nvim .`)
			if vim.fn.argc(-1) == 1 then
				local stat = vim.uv.fs_stat(vim.fn.argv(0))
				if stat and stat.type == "directory" then
					require("neo-tree")
				end
			end
		end,
		opts = {
			close_if_last_window = true,
			popup_border_style = "rounded",
			filesystem = {
				bind_to_cwd = false,
				follow_current_file = { enabled = true },
				use_libuv_file_watcher = true,
				filtered_items = {
					visible = false,
					hide_dotfiles = false,
					hide_gitignored = false,
				},
			},
			window = {
				width = 40,
				mappings = {
					["<space>"] = "none",
					["l"] = "open",
					["h"] = "close_node",
				},
			},
			default_component_configs = {
				indent = {
					with_expanders = true,
					expander_collapsed = "",
					expander_expanded = "",
				},
			},
		},
	},

	---------------------------------------------------------------------
	-- nvim-highlight-colors: Hiển thị ô màu Virtual Text như VS Code
	{
		"brenoprata10/nvim-highlight-colors",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			render = "virtual", -- Chế độ 'virtual': hiện ô vuông màu bên cạnh
			virtual_symbol = "■", -- Ký tự ô vuông màu
			virtual_symbol_position = "inline", -- Đặt ngay sát mã màu
			enable_hex = true, -- Bật mã HEX (#ffffff)
			enable_rgb = true, -- Bật rgb() / rgba()
			enable_hsl = true, -- Bật hsl()
			enable_var_usage = true, -- Bật biến CSS var(--...)
			enable_named_colors = true, -- Bật tên màu tiếng Anh (red, blue...)
			enable_tailwind = true, -- Bật nhận diện class màu Tailwind CSS
		},
	},
}
