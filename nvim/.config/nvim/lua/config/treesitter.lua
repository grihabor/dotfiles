return {
    "nvim-treesitter/nvim-treesitter",
    opts = {
        ensure_installed = {
            "css",
            "git_rebase",
            "gotmpl",
            "html",
            "javascript",
            "json",
            "lua",
            "nix",
            "python",
            "rust",
            "sql",
            "toml",
            "yaml",
        },
        auto_install = true,
        highlight = { enable = true, additional_vim_regex_highlighting = false },
        ident = { enable = true },
        rainbow = { enable = true, extended_mode = true, max_file_lines = nil },
    },
    config = function(_, opts)
        local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
        parser_config.gotmpl = {
            install_info = {
                url = "https://github.com/ngalaiko/tree-sitter-go-template",
                files = { "src/parser.c" },
                branch = "master",
                generate_requires_npm = false,
                requires_generate_from_grammar = false,
            },
            filetype = "gotmpl",
            -- used_by = { "gohtmltmpl", "gotexttmpl", "gotmpl", "yaml" },
        }

        require("nvim-treesitter.configs").setup(opts)
    end,
}
