return {
    setup = function()
        require("quickfix_command").setup({
            commands = {
                pants_mypy_forge = {
                    command = function(dir)
                        return "pants --no-dynamic-ui --no-colors check --only=mypy " .. dir .. "::"
                    end,
                    input = {
                        prompt = "Target directory",
                    },
                    keymap = "<leader>pm",
                    desc = "Run pants mypy for chosen dir",
                    title = "pants mypy",
                },
            },
        })
    end,
}
