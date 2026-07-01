return {
    setup = function()
        require("quickfix_command").setup({
            commands = {
                pants_mypy_forge = {
                    command = function()
                        return "pants --no-dynamic-ui check --only=mypy " .. vim.fn.getcwd() .. "::"
                    end,
                    keymap = "<leader>pm",
                    desc = "Run pants mypy for current dir",
                    title = "pants mypy",
                },
            },
        })
    end,
}
