local array = require("array")
local plugins = {
    {
        -- from current buffer
        dependency = "hrsh7th/cmp-buffer",
        source = { name = "buffer", keyword_length = 2 },
    },
    {
        -- from language server
        dependency = "hrsh7th/cmp-nvim-lsp",
        source = { name = "nvim_lsp", keyword_length = 3 },
    },
    {
        -- display function signatures with current parameter emphasized
        dependency = "hrsh7th/cmp-nvim-lsp-signature-help",
        source = { name = "nvim_lsp_signature_help" },
    },
    {
        -- complete neovim's Lua runtime API such vim.lsp.*
        dependency = "hrsh7th/cmp-nvim-lua",
        source = { name = "nvim_lua", keyword_length = 2 },
    },
    {
        -- file paths
        dependency = "hrsh7th/cmp-path",
        source = { name = "path" },
    },
}

local dependencies = array.map(plugins, function(p)
    return p.dependency
end)
table.insert(dependencies, "hrsh7th/cmp-cmdline")

local sources = array.map(plugins, function(p)
    return p.source
end)

return {
    "hrsh7th/nvim-cmp",
    dependencies = dependencies,

    init = function()
        -- Set completeopt to have a better completion experience
        -- :help completeopt
        -- menuone: popup even when there's only one match
        -- noinsert: Do not insert text until a selection is made
        -- noselect: Do not select, force to select one from the menu
        -- shortness: avoid showing extra messages when using completion
        -- updatetime: set updatetime for CursorHold
        vim.opt.completeopt = { "menuone", "noselect", "noinsert" }
        vim.opt.shortmess = vim.opt.shortmess + { c = true }
        vim.api.nvim_set_option("updatetime", 300)
    end,

    config = function()
        local cmp = require("cmp")
        cmp.setup({
            -- Enable LSP snippets
            snippet = {
                expand = function(args)
                    vim.fn["UltiSnips#Anon"](args.body)
                end,
            },
            mapping = {
                ["<C-p>"] = cmp.mapping.select_prev_item(),
                ["<C-n>"] = cmp.mapping.select_next_item(),
                ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                ["<C-u>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.close(),
                ["<C-y>"] = cmp.mapping(
                    cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Insert,
                        select = true,
                    }),
                    { "i", "c" }
                ),
                ["<C-Y>"] = cmp.mapping(
                    cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    }),
                    { "i", "c" }
                ),
            },
            sources = sources,
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },
            formatting = {
                fields = { "menu", "abbr", "kind" },
                format = function(entry, item)
                    local menu_icon = {
                        nvim_lsp = "λ",
                        vsnip = "⋗",
                        buffer = "Ω",
                        path = "🖫",
                    }
                    item.menu = menu_icon[entry.source.name]
                    return item
                end,
            },
        })

        -- Use buffer source for `/` and `?`
        cmp.setup.cmdline({ "/", "?" }, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = "buffer" },
            },
        })

        -- Use cmdline & path source for ':'
        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = "path" },
            }, {
                { name = "cmdline" },
            }),
            matching = { disallow_symbol_nonprefix_matching = false },
        })
    end,
}
