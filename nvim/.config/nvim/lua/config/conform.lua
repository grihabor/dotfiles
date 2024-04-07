dict = require("dict")
local formatters_by_ft = {
    java = { "google-java-format" },
    json = { "jq" },
    lua = { "stylua" },
    nix = { "alejandra" },
    python = { "isort", "black" }, -- Conform will run multiple formatters sequentially.
    sh = { "shfmt" },
    sql = { "sqlfluff" },
    xml = { "xmlformat" },
    rust = {},
}
return {
    "stevearc/conform.nvim",
    ft = dict.keys(formatters_by_ft),
    opts = {
        formatters_by_ft = formatters_by_ft,
    },
    config = function(_, opts)
        require("conform").setup(opts)

        vim.keymap.set("n", "<space>f", function()
            require("conform").format({ async = true, lsp_fallback = true, quiet = false })
        end, bufopts)
    end,
}
