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
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set("n", "<space>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, bufopts)
    vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, bufopts)
    -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)

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
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    local lspconfig = require("lspconfig")

    -- lspconfig.pylyzer.setup{
    --     on_attach=on_attach,
    --     capabilities=capabilities,
    -- }
    lspconfig.ts_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
    })
    -- lspconfig.pylsp.setup{
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
    -- lspconfig.rust_analyzer.setup({
    --     on_attach = on_attach,
    --     capabilities = capabilities,
    -- })

    lspconfig.lua_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
    })

    lspconfig.jdtls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
    })

    lspconfig.yamlls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
    })

    lspconfig.nil_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
    })

    lspconfig.pyright.setup({
        on_attach = on_attach,
        capabilities = capabilities,
    })

    lspconfig.gopls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
    })

    -- require("config.pyny")({
    --     on_attach = on_attach,
    --     capabilities = capabilities,
    -- })
end

return {
    on_attach = on_attach,
    config = config,
}
