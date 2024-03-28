return require("lazy").setup({

    { "folke/neodev.nvim", opts = {
        library = { plugins = { "nvim-dap-ui" }, types = true },
    } },

    -- general purpuse plugins
    "tpope/vim-repeat",
    "tpope/vim-surround",
    "tpope/vim-abolish",
    "tpope/vim-unimpaired",
    "godlygeek/tabular", -- tmux
    -- "christoomey/vim-tmux-navigator",
    -- "HiPhish/jinja.vim",
    -- "vim-test/vim-test",
    -- automatically create pairs of braces, brackets, etc.
    -- use 'm4xshen/autoclose.nvim'
    -- open files from nvim terminal without nested sessions
    "mhinz/neovim-remote", -- manage files in regular vim buffer
    {
        "stevearc/oil.nvim",
        opts = {},
        -- Optional dependencies
        dependencies = { "nvim-tree/nvim-web-devicons" },
    }, -- git
    "tpope/vim-fugitive", -- autosave
    "Pocco81/auto-save.nvim", -- fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        dependencies = { "nvim-lua/plenary.nvim" },
    },
    {
        "nvim-telescope/telescope-file-browser.nvim",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim",
        },
    }, -- color theme
    -- use 'morhetz/gruvbox'
    "ellisonleao/gruvbox.nvim", -- use 'Mofiqul/dracula.nvim'
    -- use 'folke/tokyonight.nvim'
    -- use 'sainnhe/sonokai'
    -- lsp configurations
    "neovim/nvim-lspconfig", -- lsp progress messages and notifications
    "j-hui/fidget.nvim", -- use 'nvim-lua/lsp-status.nvim'
    -- completion framework:
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lua",
    "hrsh7th/cmp-nvim-lsp-signature-help", -- code snippets
    "SirVer/ultisnips",
    "quangnguyen30192/cmp-nvim-ultisnips",

    -- language parsers
    { "nvim-treesitter/nvim-treesitter", config = require("options.treesitter") },
    -- "chr4/nginx.vim",

    -- scala
    require("config.metals"), -- rust
    "simrat39/rust-tools.nvim", -- python
    -- use({
    -- 	"psf/black",
    -- 	branch = "stable",
    -- })
    { "python-rope/ropevim", ft = "python" }, -- formatters
    "stevearc/conform.nvim",
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
