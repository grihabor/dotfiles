return {
    "nvim-neotest/neotest",
    dependencies = {
        "mrcjkb/rustaceanvim",
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
