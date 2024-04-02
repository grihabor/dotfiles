return require("lazy").setup({

    {
        "folke/neodev.nvim",
        opts = {
            library = { plugins = { "nvim-dap-ui" }, types = true },
        },
    },

    --
    -- general purpuse plugins
    --
    "tpope/vim-repeat",
    "tpope/vim-surround",
    "tpope/vim-abolish",
    "tpope/vim-unimpaired",
    -- align text in columns
    "godlygeek/tabular",
    -- open files from nvim terminal without nested sessions
    "mhinz/neovim-remote",
    {
        -- manage files in regular vim buffer
        "stevearc/oil.nvim",
        opts = {
            view_options = {
                show_hidden = true,
            },
        },
        -- Optional dependencies
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
    -- git
    "tpope/vim-fugitive",
    -- autosave
    "Pocco81/auto-save.nvim",
    -- fuzzy finder
    require("config.telescope"),
    {
        "nvim-telescope/telescope-file-browser.nvim",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim",
        },
    },
    {
        -- color theme
        "ellisonleao/gruvbox.nvim",
        config = function()
            vim.o.background = "dark"
            vim.cmd([[colorscheme gruvbox]])
        end,
    },

    -- lsp configurations
    { "neovim/nvim-lspconfig", config = require("config.lsp") },

    -- lsp progress messages and notifications
    "j-hui/fidget.nvim",

    -- completion framework:
    require("config.completion"),
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-nvim-lua",
    "hrsh7th/cmp-nvim-lsp-signature-help",
    "hrsh7th/cmp-cmdline",
    { "quangnguyen30192/cmp-nvim-ultisnips", dependencies = { "SirVer/ultisnips" } },
    "SirVer/ultisnips",

    -- language parsers
    require("config.treesitter"),

    -- scala
    require("config.metals"),
    -- rust
    "simrat39/rust-tools.nvim",
    {
        -- python refactoring
        "python-rope/ropevim",
        ft = "python",
        config = function()
            ropevim_path = os.getenv("HOME") .. "/.local/share/nvim/lazy/ropevim/ftplugin/python_ropevim.vim"
            if vim.fn.filereadable(ropevim_path) then
                vim.cmd("source " .. ropevim_path)
            end
        end,
    },

    -- formatters
    require("config.conform"),
    require("config.lint"),

    { "folke/trouble.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },

    -- package manager for lsp, linter, formatters
    "williamboman/mason.nvim", -- debugger

    require("config.dap"),
    {
        "mfussenegger/nvim-dap-python",
        config = function()
            require("dap-python").setup("~/.pyenv/versions/3.11.6/bin/python")
            require("dap-python").test_runner = "pytest"
        end,
    },
    { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap" } },
})
