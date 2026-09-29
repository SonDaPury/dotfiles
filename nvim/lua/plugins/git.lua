return {
	-----------------------------------------------------------------------------
	-- lewis6991/gitsigns.nvim: Trải nghiệm GitLens với Line Blame & Hunk actions
	-----------------------------------------------------------------------------
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			-- Tự động hiện tác giả & commit mờ ở đuôi dòng con trỏ (giống hệt GitLens)
			current_line_blame = true,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol", -- Hiện ở cuối dòng
				delay = 300, -- Độ trễ 300ms sau khi dừng con trỏ
				ignore_whitespace = false,
			},
			current_line_blame_formatter = " <author>, <author_time:%Y-%m-%d> • <summary>",
			preview_config = {
				border = "rounded",
				style = "minimal",
				relative = "cursor",
				row = 0,
				col = 1,
			},
		},
		keys = {
			-- Di chuyển giữa các khối code thay đổi (Hunks)
			{
				"]h",
				function()
					if vim.wo.diff then
						return "]h"
					end
					vim.schedule(function()
						require("gitsigns").next_hunk()
					end)
					return "<Ignore>"
				end,
				expr = true,
				desc = "Git: Nhảy tới hunk tiếp theo",
			},
			{
				"[h",
				function()
					if vim.wo.diff then
						return "[h"
					end
					vim.schedule(function()
						require("gitsigns").prev_hunk()
					end)
					return "<Ignore>"
				end,
				expr = true,
				desc = "Git: Nhảy tới hunk trước đó",
			},

			-- Thao tác khối code & xem Blame
			{
				"<leader>gp",
				function()
					require("gitsigns").preview_hunk()
				end,
				desc = "Git: Xem trước diff của khối code (Preview hunk)",
			},
			{
				"<leader>gb",
				function()
					require("gitsigns").blame_line({ full = true })
				end,
				desc = "Git: Popup xem chi tiết tác giả dòng hiện tại",
			},
			{
				"<leader>gB",
				function()
					require("gitsigns").toggle_current_line_blame()
				end,
				desc = "Git: Bật/Tắt dòng chữ blame mờ ở đuôi con trỏ",
			},
			{
				"<leader>gs",
				function()
					require("gitsigns").stage_hunk()
				end,
				mode = { "n", "v" },
				desc = "Git: Stage khối code hiện tại",
			},
			{
				"<leader>gr",
				function()
					require("gitsigns").reset_hunk()
				end,
				mode = { "n", "v" },
				desc = "Git: Hoàn tác (reset) khối code hiện tại",
			},
			{
				"<leader>gS",
				function()
					require("gitsigns").stage_buffer()
				end,
				desc = "Git: Stage toàn bộ file",
			},
			{
				"<leader>gR",
				function()
					require("gitsigns").reset_buffer()
				end,
				desc = "Git: Hoàn tác toàn bộ file",
			},
			{
				"<leader>gd",
				function()
					require("gitsigns").diffthis()
				end,
				desc = "Git: So sánh diff file hiện tại với index",
			},
		},
	},

	-----------------------------------------------------------------------------
	-- sindrets/diffview.nvim: So sánh Diff trực quan & Xem lịch sử file (File History)
	-----------------------------------------------------------------------------
	{
		"sindrets/diffview.nvim",
		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewToggleFiles",
			"DiffviewFocusFiles",
			"DiffviewFileHistory",
		},
		keys = {
			{
				"<leader>gv",
				"<cmd>DiffviewOpen<CR>",
				desc = "Git: Mở giao diện so sánh Diff toàn dự án",
			},
			{
				"<leader>gq",
				"<cmd>DiffviewClose<CR>",
				desc = "Git: Đóng giao diện Diffview",
			},
			{
				"<leader>gh",
				"<cmd>DiffviewFileHistory %<CR>",
				desc = "Git: Xem lịch sử commit của file hiện tại (File History)",
			},
			{
				"<leader>gH",
				"<cmd>DiffviewFileHistory<CR>",
				desc = "Git: Xem lịch sử commit của toàn bộ Branch",
			},
		},
		opts = {
			enhanced_diff_hl = true,
			view = {
				default = {
					layout = "diff2_horizontal",
				},
			},
		},
	},

	-----------------------------------------------------------------------------
	-- kdheepak/lazygit.nvim: Giao diện Git GUI nổi toàn diện
	-----------------------------------------------------------------------------
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		keys = {
			{
				"<leader>gg",
				"<cmd>LazyGit<CR>",
				desc = "Git: Mở Lazygit GUI toàn màn hình",
			},
		},
	},
}
