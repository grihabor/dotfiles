local python3_host_prog = os.getenv('HOME') .. '/.pyenv/versions/py3nvim/bin/python'
if vim.fn.executable(python3_host_prog) then
    vim.g.python3_host_prog = python3_host_prog
end

require('plugins')
require('keymaps')
require('options')

-- vim.g.gruvbox_contrast_dark = "hard"
-- vim.g.gruvbox_improved_warnings = 1
-- vim.cmd "autocmd vimenter * ++nested colorscheme gruvbox"

vim.o.background = "dark"
vim.cmd([[colorscheme gruvbox]])

-- vim.cmd[[colorscheme dracula]]
-- vim.cmd[[colorscheme tokyonight]]
-- vim.cmd[[colorscheme sonokai]]

-- use clipboard for yank and delete
vim.opt.clipboard = 'unnamedplus'

-- hybrid line numbers
vim.wo.number = true
vim.wo.relativenumber = true

vim.cmd "filetype plugin indent on"
-- show existing tab with 4 spaces width
vim.opt.tabstop = 4
-- when indenting with '>', use 4 spaces width
vim.opt.shiftwidth = 4
-- On pressing tab, insert 4 spaces
vim.opt.expandtab = true

vim.opt.swapfile = false

