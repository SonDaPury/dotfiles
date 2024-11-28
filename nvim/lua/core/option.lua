local opt = vim.opt -- for conciseness

-- line numbers
opt.number = true
--opt.relativenumber = true

-- encoding
opt.encoding = "UTF-8"

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- search settings
opt.ignorecase = true
opt.smartcase = true

-- cursor line
opt.cursorline = true

-- appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

-- backspace
opt.backspace = "indent,eol,start"

-- clipboard
vim.cmd([[set clipboard+=unnamedplus]])

-- split window
opt.splitright = true
opt.splitbelow = true
opt.iskeyword:append("-")

vim.opt.wildoptions = "pum"

-- folding
vim.o.foldcolumn = '1'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
