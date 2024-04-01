-- https://github.com/nvim-telescope/telescope.nvim/issues/2201#issuecomment-1284691502
local ts_select_dir_for_grep = function(prompt_bufnr)
    local action_state = require("telescope.actions.state")
    local fb = require("telescope").extensions.file_browser
    local live_grep = require("telescope.builtin").live_grep
    local current_line = action_state.get_current_line()

    fb.file_browser({
        files = false,
        depth = false,
        attach_mappings = function(prompt_bufnr)
            require("telescope.actions").select_default:replace(function()
                local entry_path = action_state.get_selected_entry().Path
                local dir = entry_path:is_dir() and entry_path or entry_path:parent()
                local relative = dir:make_relative(vim.fn.getcwd())
                local absolute = dir:absolute()

                live_grep({
                    results_title = relative .. "/",
                    cwd = absolute,
                    default_text = current_line,
                })
            end)

            return true
        end,
    })
end

return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local actions = require("telescope.actions")
        local config = require("telescope.config")
        local action_layout = require("telescope.actions.layout")

        require("telescope").setup({
            defaults = {
                -- `hidden = true` is not supported in text grep commands.
                vimgrep_arguments = (function()
                    -- Clone the default Telescope configuration
                    local vimgrep_arguments = { unpack(config.values.vimgrep_arguments) }

                    -- I want to search in hidden/dot files.
                    table.insert(vimgrep_arguments, "--hidden")
                    -- I don't want to search in the `.git` directory.
                    table.insert(vimgrep_arguments, "--glob")
                    table.insert(vimgrep_arguments, "!**/.git/*")

                    return vimgrep_arguments
                end)(),
                layout_config = {
                    horizontal = { width = 0.99, height = 0.99, preview_width = 0.5 },
                },
                mappings = {
                    i = {
                        ["<esc>"] = actions.close,
                        ["<M-p>"] = action_layout.toggle_preview,
                        ["<C-f>"] = ts_select_dir_for_grep,
                    },
                    n = {
                        ["<C-f>"] = ts_select_dir_for_grep,
                        ["<M-p>"] = action_layout.toggle_preview,
                    },
                },
            },
            pickers = {
                find_files = {
                    -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
                    find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
                },
            },
        })

        local builtin = require("telescope.builtin")
        options = { path_display = { "truncate" } }
        vim.keymap.set("n", "<leader>ff", function()
            builtin.find_files(options)
        end, {})
        vim.keymap.set("n", "<leader>fg", function()
            builtin.live_grep(options)
        end, {})
        vim.keymap.set("n", "<leader>fs", builtin.grep_string, {})
        vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
    end,
}
