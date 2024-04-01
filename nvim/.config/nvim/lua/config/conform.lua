local formatters_by_ft = {
    java = { "google-java-format" },
    json = { "jq" },
    lua = { "stylua" },
    nix = { "alejandra" },
    python = { "isort", "black" }, -- Conform will run multiple formatters sequentially.
    sh = { "shfmt" },
    sql = { "sqlfluff" },
    xml = { "xmlformat" },
}
local function get_keys(tbl)
    local keyset = {}
    local n = 0

    for k, _ in pairs(tbl) do
        n = n + 1
        keyset[n] = k
    end

    return keyset
end
return {
    "stevearc/conform.nvim",
    ft = get_keys(formatters_by_ft),
    opts = {
        formatters_by_ft = formatters_by_ft,
    },
    init = function()
        -- Register pants BUILD files.
        vim.filetype.add({ filename = { ["BUILD"] = "python" } })
    end,
    config = function(_, opts)
        require("conform").setup(opts)

        vim.keymap.set("n", "<space>f", function()
            require("conform").format({ async = true, lsp_fallback = true, quiet = false })
        end, bufopts)
    end,
}
