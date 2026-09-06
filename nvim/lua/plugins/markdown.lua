return {
  -- MeanderingProgrammer/render-markdown.nvim: render heading/bullet/code block/table/checkbox
  -- ngay trong buffer bằng treesitter, không cần trình duyệt hay Node.js
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>mp", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown Preview" },
    },
    opts = {
      enabled = false,
      -- không ẩn phần render ở dòng con trỏ, giữ preview kiểu Obsidian khi gõ
      anti_conceal = {
        enabled = false,
      },
    },
  },
}
