
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

local telescope_builtin = require('telescope.builtin')

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)

  vim.keymap.set('n', 'gr', function() 
      telescope_builtin.lsp_references()
  end )
  vim.keymap.set('n', '<leader>fs', function()
        vim.ui.input({ prompt = "Workspace symbols: " }, function(query)
                telescope_builtin.lsp_workspace_symbols({ query = query })
        end)
  end, { desc = "LSP workspace symbols" })
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()
require'lspconfig'.pyright.setup{
    on_attach = on_attach,
    capabilities=capabilities,
}
require'lspconfig'.tsserver.setup{
    on_attach = on_attach,
    capabilities=capabilities,
}
-- require'lspconfig'.pylsp.setup{
--     on_attach = on_attach,
--     capabilities = capabilities,
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

-- Don't configure lspconfig for rust because it is managed by rust-tools

