return require("lazy").setup({

    {
        "folke/neodev.nvim",
        opts = {
            library = { plugins = { "neotest", "nvim-dap-ui" }, types = true },
        },
    },

    --
    -- general purpuse plugins
    --
    "tpope/vim-repeat",
    "tpope/vim-surround",
    "tpope/vim-abolish",
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
                is_always_hidden = function(name, bufnr)
                    return false
                end,
            },
        },
        -- Optional dependencies
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function(opts)
            require("oil").setup(opts)
            vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
        end,
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
    -- "RRethy/vim-illuminate",
    {
        -- color theme
        "ellisonleao/gruvbox.nvim",
        config = function()
            vim.o.background = "dark"
            vim.cmd([[colorscheme gruvbox]])
        end,
    },

    -- lsp configurations
    {
        "neovim/nvim-lspconfig",
        config = require("config.lsp").config,
    },

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

    -- language parsers
    require("config.treesitter"),
    "nvim-treesitter/nvim-treesitter-textobjects",

    -- scala
    require("config.metals"),
    -- rust
    require("config.rustaceanvim"),
    -- {
    --     -- python refactoring
    --     "python-rope/ropevim",
    --     ft = "python",
    --     config = function()
    --         local ropevim_path = os.getenv("HOME") .. "/.local/share/nvim/lazy/ropevim/ftplugin/python_ropevim.vim"
    --         if vim.fn.filereadable(ropevim_path) then
    --             vim.cmd("source " .. ropevim_path)
    --         end
    --     end,
    -- },

    -- formatters
    require("config.conform"),
    require("config.lint"),

    { "folke/trouble.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },

    -- package manager for lsp, linter, formatters
    "williamboman/mason.nvim", -- debugger

    require("config.dap"),
    require("config.neotest"),
    {
        "mfussenegger/nvim-dap-python",
        config = function()
            require("dap-python").setup("~/.nix-profile/bin/python3.11")
            require("dap-python").test_runner = "pytest"

            vim.keymap.set("n", "<leader>tf", function()
                require("dap-python").test_method()
            end)
            vim.keymap.set("n", "<leader>tc", function()
                require("dap-python").test_class()
            end)
            vim.keymap.set("n", "<leader>ts", function()
                require("dap-python").debug_selection()
            end)
        end,
    },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio",
        },
        config = function(opts)
            local dap, dapui = require("dap"), require("dapui")
            dapui.setup(opts)

            dap.listeners.before.attach.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.launch.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated.dapui_config = function()
                dapui.close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                dapui.close()
            end
        end,
    },
    --
    -- kitty plugins
    {
        "mikesmithgh/kitty-scrollback.nvim",
        enabled = true,
        lazy = true,
        cmd = {
            "KittyScrollbackGenerateKittens",
            "KittyScrollbackCheckHealth",
            "KittyScrollbackGenerateCommandLineEditing",
        },
        event = { "User KittyScrollbackLaunch" },
        -- version = '*', -- latest stable version, may have breaking changes if major version changed
        -- version = '^6.0.0', -- pin major version, include fixes and features that do not have breaking changes
        config = function()
            require("kitty-scrollback").setup()
        end,
    },
})
