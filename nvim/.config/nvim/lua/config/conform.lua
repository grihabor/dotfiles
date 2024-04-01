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
local function get_keys(table)
    local keyset = {}
    local n = 0

    for k, _ in pairs(table) do
        n = n + 1
        keyset[n] = k
    end

    return keyset
end
return {
    "stevearc/conform.nvim",
    ft = get_keys(formatters_by_ft),
    opts = {
        -- formatters_by_ft = formatters_by_ft,
        -- formatters = {
        --     black = {
        --         command = "/nix/store/7vmbm0dpl7z73ybgbq7xybxfzy5vvfxz-python3.11-black-23.9.1/bin/black",
        --     },
        -- },
    },
    init = function()
        -- Register pants BUILD files.
        vim.filetype.add({ filename = { ["BUILD"] = "python" } })
    end,
    config = function()
        require("conform").setup({
            formatters_by_ft = formatters_by_ft,
        })
        vim.keymap.set("n", "<space>f", function()
            require("conform").format({ async = true, lsp_fallback = true, quiet = false })
        end, bufopts)
    end,
}
