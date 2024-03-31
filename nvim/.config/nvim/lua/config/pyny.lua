return function(config)
    local lspconfig = require("lspconfig")
    local util = require("lspconfig.util")
    local configs = require("lspconfig.configs")

    local root_files = {
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        ".git",
    }
    if not configs.pyny then
        configs.pyny = {
            default_config = {
                cmd = { "/home/grihabor/projects/pyny/target/release/pyny" },
                filetypes = { "python" },
                root_dir = function(fname)
                    return util.root_pattern(unpack(root_files))(fname)
                end,
                settings = {},
            },
        }
    end
    lspconfig.pyny.setup({
        on_attach = config.on_attach,
        capabilities = config.capabilities,
    })

    vim.lsp.set_log_level("info")
end
