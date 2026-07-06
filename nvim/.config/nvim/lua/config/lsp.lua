-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    local telescope_builtin = require("telescope.builtin")
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
    vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set("n", "<space>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, bufopts)

    vim.keymap.set("n", "gr", function()
        telescope_builtin.lsp_references()
    end)

    -- all workspace diagnostics
    vim.keymap.set("n", "<leader>qd", vim.diagnostic.setqflist)

    -- all workspace errors
    vim.keymap.set("n", "<leader>qe", function()
        vim.diagnostic.setqflist({ severity = "E" })
    end)

    -- all workspace warnings
    vim.keymap.set("n", "<leader>qw", function()
        vim.diagnostic.setqflist({ severity = "W" })
    end)

    -- buffer diagnostics only
    vim.keymap.set("n", "<leader>qb", vim.diagnostic.setloclist)

    vim.keymap.set("n", "<space>ws", function()
        vim.ui.input({ prompt = "Workspace symbols: " }, function(query)
            telescope_builtin.lsp_workspace_symbols({ query = query })
        end)
    end, { desc = "LSP workspace symbols" })
end

local config = function()
    local opts = { noremap = true, silent = true }
    vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- vim.lsp.config('pylyzer',{
    --     on_attach=on_attach,
    --     capabilities=capabilities,
    -- }

    vim.lsp.config("ts_ls", {
        on_attach = on_attach,
        capabilities = capabilities,
    })
    vim.lsp.enable("ts_ls")

    -- vim.lsp.config('pylsp',{
    --     on_attach=on_attach,
    --     capabilities=capabilities,
    --   settings = {
    --     pylsp = {
    --       plugins = {
    --           pycodestyle = {enabled = false},
    --           mccabe = {enabled = false},
    --           pyflakes = {enabled = false},
    --           flake8 = {enabled = true},
    --           rope_autoimport = {enabled = true},
    --       }
    --     }
    --   }
    -- }
    -- vim.lsp.config('rust_analyzer',{
    --     on_attach = on_attach,
    --     capabilities = capabilities,
    -- })

    vim.lsp.config("lua_ls", {
        on_attach = on_attach,
        capabilities = capabilities,
    })
    vim.lsp.enable("lua_ls")

    vim.lsp.config("jdtls", {
        on_attach = on_attach,
        capabilities = capabilities,
    })
    vim.lsp.enable("jdtls")

    vim.lsp.config("yamlls", {
        on_attach = on_attach,
        capabilities = capabilities,
    })
    vim.lsp.enable("yamlls")

    vim.lsp.config("nil_ls", {
        on_attach = on_attach,
        capabilities = capabilities,
    })
    vim.lsp.enable("nil_ls")

    vim.lsp.config("ty", {
        on_attach = on_attach,
        capabilities = capabilities,
    })
    vim.lsp.enable("ty")

    -- vim.lsp.config("pyrefly", {
    --     -- example of how to run `uv` installed Pyrefly without adding to your path
    --     cmd = { "uvx", "pyrefly", "lsp" },
    --     filetypes = { "python" },
    --     on_attach = on_attach,
    --     capabilities = capabilities,
    -- })

    vim.lsp.config("gopls", {
        on_attach = on_attach,
        capabilities = capabilities,
    })
    vim.lsp.enable("gopls")

    -- require("config.pyny")({
    --     on_attach = on_attach,
    --     capabilities = capabilities,
    -- })
end

return {
    on_attach = on_attach,
    config = config,
}
