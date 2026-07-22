local M = {}

-- sort words within a visual selection (must be called with a selection active)
function M.sort_visual_selection()
    -- yank the selection into register z without clobbering the user's registers
    local save_reg = vim.fn.getreg("z")
    local save_type = vim.fn.getregtype("z")
    vim.cmd('noautocmd normal! "zy')

    local text = vim.fn.getreg("z")

    -- comma-separated list -> split on commas, otherwise split on whitespace
    local pattern, join
    if text:find(",") then
        pattern, join = "[^,]+", ", "
    else
        pattern, join = "%S+", " "
    end

    local words = {}
    for word in text:gmatch(pattern) do
        word = word:gsub("^%s+", ""):gsub("%s+$", "")
        if word ~= "" then
            table.insert(words, word)
        end
    end
    table.sort(words)

    -- paste the sorted text back over the (re-)selected region
    vim.fn.setreg("z", table.concat(words, join), "v")
    vim.cmd('noautocmd normal! gv"zp')

    vim.fn.setreg("z", save_reg, save_type)
end

function M.setup(opts)
    opts = opts or {}

    if opts.keymap ~= false then
        vim.keymap.set("x", opts.keymap or "<leader>sw", M.sort_visual_selection, {
            desc = "Sort selected words",
        })
    end

    vim.api.nvim_create_user_command("SortWords", function()
        -- ':' leaves visual mode, so restore the last selection first
        vim.cmd("noautocmd normal! gv")
        M.sort_visual_selection()
    end, { range = true, desc = "Sort whitespace-separated words in selection" })
end

return M
