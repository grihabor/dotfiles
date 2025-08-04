--
-- lazy.nvim
--
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

vim.filetype.add({
    extension = {
        tpl = "gotmpl", -- go template files
        hql = "sql", -- hive query language
        mdx = "markdown", -- https://mdxjs.com/
    },
    filename = {
        ["BUILD"] = "python", -- pants BUILD files
        ["pdm.lock"] = "toml", -- pdm lock files
    },
    pattern = {
        ["BUILD%..+"] = "python", -- pants BUILD files
        ["Dockerfile%..+"] = "dockerfile",
    },
})

require("lazy").setup(require("plugins"), {})

--
-- python
--
local python3_host_prog = os.getenv("HOME") .. "/.nix-profile/bin/python-nix"
if vim.fn.executable(python3_host_prog) then
    vim.g.python3_host_prog = python3_host_prog
end

-- vim.cmd[[colorscheme dracula]]
-- vim.cmd[[colorscheme tokyonight]]
-- vim.cmd[[colorscheme sonokai]]

-- use clipboard for yank and delete
vim.opt.clipboard = "unnamedplus"

-- hybrid line numbers
vim.wo.number = true
vim.wo.relativenumber = true

vim.cmd("filetype plugin indent on")
-- show existing tab with 4 spaces width
vim.opt.tabstop = 4
-- when indenting with '>', use 4 spaces width
vim.opt.shiftwidth = 4
-- On pressing tab, insert 4 spaces
vim.opt.expandtab = true

vim.opt.swapfile = false

-- LSP Diagnostics Options Setup
local sign = function(opts)
    vim.fn.sign_define(opts.name, { texthl = opts.name, text = opts.text, numhl = "" })
end

sign({ name = "DiagnosticSignError", text = "" })
sign({ name = "DiagnosticSignWarn", text = "" })
sign({ name = "DiagnosticSignHint", text = "" })
sign({ name = "DiagnosticSignInfo", text = "" })

vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    update_in_insert = true,
    underline = true,
    severity_sort = false,
    float = { border = "rounded", source = "always", header = "", prefix = "" },
})

-- match tmux-sensible
vim.keymap.set("n", "<C-w>x", "<C-w>c")
vim.keymap.set("n", "<C-w>c", "<Nop>")
vim.keymap.set("n", "<C-w>|", "<C-w>v")
vim.keymap.set("n", "<C-w>-", "<C-w>s")
