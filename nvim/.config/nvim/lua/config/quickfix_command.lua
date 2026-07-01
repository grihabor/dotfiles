return {
    setup = function()
        require("quickfix_command").setup({
            commands = {
                pants_mypy_forge = {
                    command = "pants mypy src/python/tools/forge",
                    keymap = "<leader>pm",
                    desc = "Run pants mypy for forge",
                    title = "pants mypy src/python/tools/forge",
                },
            },
        })
    end,
}
