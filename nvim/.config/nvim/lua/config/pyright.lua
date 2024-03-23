local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local lsp = require("keymaps.lsp")

lspconfig.pyright.setup({
    on_attach = lsp.on_attach({ use_conform = true }),
    capabilities = capabilities,
})
