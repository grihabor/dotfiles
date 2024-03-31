return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            -- Customize or remove this keymap to your liking
            "<space>f",
            function()
                require("conform").format({ async = true, lsp_fallback = true })
            end,
            mode = "",
            desc = "Format buffer",
        },
    },
    opts = {
        formatters_by_ft = {
            java = { "google-java-format" },
            json = { "jq" },
            lua = { "stylua" },
            nix = { "nixfmt" },
            python = { "isort", "black" }, -- Conform will run multiple formatters sequentially.
            sh = { "shfmt" },
            sql = { "sqlfluff" },
            xml = { "xmlformat" },
        },
    },
    config = function()
        -- Register pants BUILD files.
        vim.filetype.add({ filename = { ["BUILD"] = "python" } })
    end,
}
