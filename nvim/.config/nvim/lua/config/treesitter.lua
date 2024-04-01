return {
    "nvim-treesitter/nvim-treesitter",
    opts = {
        ensure_installed = {
            "css",
            "git_rebase",
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
        require("nvim-treesitter.configs").setup(opts)
    end,
}
