dict = require("dict")
local formatters_by_ft = {
    c = { "clang-format" },
    cue = { "cue_fmt" },
    html = { "htmlbeautifier" },
    java = { "google-java-format" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    json = { "jq" },
    lua = { "stylua" },
    nix = { "alejandra" },
    python = { "ruff_fix", "ruff_format" },
    rust = {},
    sh = { "shfmt" },
    sql = { "sqlfluff" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    xml = { "xmlformat" },
    yaml = { "yq" },
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
