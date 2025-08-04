return {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false,
    config = function()
        vim.g.rustaceanvim = (function()
            local extension_path = vim.env.HOME .. "/.nix-profile/share/vscode/extensions/vadimcn.vscode-lldb/"
            local codelldb_path = extension_path .. "adapter/codelldb"
            local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

            local cfg = require("rustaceanvim.config")
            return {
                server = {
                    on_attach = require("config.lsp").on_attach,
                },
                dap = {
                    adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
                },
            }
        end)()
    end,
}
