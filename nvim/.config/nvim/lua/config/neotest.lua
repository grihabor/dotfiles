return {
    "nvim-neotest/neotest",
    dependencies = {
        "antoinemadec/FixCursorHold.nvim",
        "mrcjkb/rustaceanvim",
        "nvim-lua/plenary.nvim",
        "nvim-neotest/nvim-nio",
        "nvim-treesitter/nvim-treesitter",
    },
    keys = {
        {
            "<leader>tr",
            function()
                require("neotest").run.run()
            end,
            desc = "Run the nearest test",
        },
        {
            "<leader>td",
            function()
                require("neotest").run.run({ strategy = "dap" })
            end,
            desc = "Debug the nearest test",
        },
        {
            "<leader>tn",
            function()
                require("neotest").run.stop()
            end,
            desc = "Stop the nearest test",
        },
        {
            "<leader>ta",
            function()
                require("neotest").run.attach()
            end,
            desc = "Attach to the nearest test",
        },
    },
    config = function()
        local opts = {
            adapters = {
                require("rustaceanvim.neotest"),
            },
        }
        require("neotest").setup(opts)
    end,
}
