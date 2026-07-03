local M = {
    commands = {},
    _bufs = {},
}

local severity_map = {
    error = "E",
    warning = "W",
    warn = "W",
    note = "I",
    info = "I",
}

local function split_lines(text)
    if not text or text == "" then
        return {}
    end

    return vim.split(text, "\n", { trimempty = true })
end

local function normalize_cwd(cwd)
    if type(cwd) == "function" then
        cwd = cwd()
    end

    return vim.fs.normalize(cwd or vim.fn.getcwd())
end

local function normalize_command(command, arg)
    if type(command) == "function" then
        command = command(arg)
    end

    if type(command) == "string" then
        local shell_command = { vim.o.shell }
        vim.list_extend(shell_command, vim.split(vim.o.shellcmdflag, "%s+", { trimempty = true }))
        table.insert(shell_command, command)
        return shell_command
    end

    if vim.islist(command) then
        return vim.deepcopy(command)
    end

    error("quickfix_command: command must be a string, list, or function")
end

local function resolve_filename(filename, cwd)
    if not filename or filename == "" then
        return nil
    end

    if filename:sub(1, 1) == "/" then
        return vim.fs.normalize(filename)
    end

    return vim.fs.normalize(vim.fs.joinpath(cwd, filename))
end

local function parse_diagnostic_line(line, cwd)
    local filename, lnum, col, kind, text = line:match("^([^:\n]+):(%d+):(%d+): ([%a_%-]+): (.+)$")
    if filename then
        return {
            filename = resolve_filename(filename, cwd),
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = text,
            type = severity_map[kind:lower()],
        }
    end

    filename, lnum, kind, text = line:match("^([^:\n]+):(%d+): ([%a_%-]+): (.+)$")
    if filename then
        return {
            filename = resolve_filename(filename, cwd),
            lnum = tonumber(lnum),
            col = 1,
            text = text,
            type = severity_map[kind:lower()],
        }
    end

    filename, lnum, text = line:match("^([^:\n]+):(%d+): (.+)$")
    if filename then
        return {
            filename = resolve_filename(filename, cwd),
            lnum = tonumber(lnum),
            col = 1,
            text = text,
        }
    end
end

local function default_parser(lines, context)
    local items = {}

    for _, line in ipairs(lines) do
        local item = parse_diagnostic_line(line, context.cwd)
        if item then
            table.insert(items, item)
        end
    end

    return items
end

local function raw_output_items(lines)
    local items = {}

    for _, line in ipairs(lines) do
        if line ~= "" then
            table.insert(items, { text = line })
        end
    end

    return items
end

local function command_names()
    local names = vim.tbl_keys(M.commands)
    table.sort(names)
    return names
end

local function complete_names(arglead)
    local matches = {}

    for _, name in ipairs(command_names()) do
        if vim.startswith(name, arglead) then
            table.insert(matches, name)
        end
    end

    return matches
end

local function set_quickfix_list(items, title)
    vim.fn.setqflist({}, " ", {
        title = title,
        items = items,
    })

    if #items > 0 then
        local win = vim.api.nvim_get_current_win()
        vim.cmd("botright copen")
        vim.api.nvim_set_current_win(win)
    end
end

local function handle_result(name, spec, cwd, result)
    local lines = split_lines(result.stdout)
    vim.list_extend(lines, split_lines(result.stderr))

    local parser = spec.parser or default_parser
    local title = spec.title or name
    local context = {
        cwd = cwd,
        code = result.code,
        signal = result.signal,
        command = spec.command,
    }

    local ok, items = pcall(parser, lines, context)
    if not ok then
        vim.notify(items, vim.log.levels.ERROR)
        return
    end

    if #items == 0 and #lines > 0 then
        items = raw_output_items(lines)
    end

    set_quickfix_list(items, title)

    local level = result.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
    vim.notify(string.format("%s finished with exit code %d", title, result.code), level)
end

local function pick_directory(prompt, callback)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local cwd = vim.fn.getcwd()
    local dirs = vim.fn.systemlist("fd --type d --hidden --exclude .git", cwd)

    pickers.new({}, {
        prompt_title = prompt or "Select directory",
        finder = finders.new_table({ results = dirs }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    vim.schedule(function()
                        callback(vim.fs.normalize(vim.fs.joinpath(cwd, selection[1])))
                    end)
                end
            end)
            return true
        end,
    }):find()
end

local function run_with_arg(name, spec, arg)
    local ok, command = pcall(normalize_command, spec.command, arg)
    if not ok then
        vim.notify(command, vim.log.levels.ERROR)
        return
    end

    local cwd = normalize_cwd(spec.cwd)
    local cmd_str = table.concat(command, " ")

    local existing_buf = M._bufs[name]
    local buf
    if existing_buf and vim.api.nvim_buf_is_valid(existing_buf) then
        buf = existing_buf
    else
        buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].swapfile = false
        M._bufs[name] = buf
    end

    local origin_win = vim.api.nvim_get_current_win()

    -- find existing window showing this buffer, or open a new one
    local buf_win = nil
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buf then
            buf_win = win
            break
        end
    end
    if not buf_win then
        vim.cmd("rightbelow vsplit")
        buf_win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(buf_win, buf)
    end

    vim.api.nvim_set_current_win(origin_win)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { cmd_str, "" })

    local accumulated = { stdout = "", stderr = "" }
    local remainder   = { stdout = "", stderr = "" }

    local function flush(key, data)
        if not data then return end
        accumulated[key] = accumulated[key] .. data
        remainder[key] = remainder[key] .. data
        local lines = vim.split(remainder[key], "\n", { plain = true })
        remainder[key] = table.remove(lines)
        if #lines > 0 then
            vim.schedule(function()
                vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
            end)
        end
    end

    vim.system(command, {
        cwd = cwd,
        text = true,
        stdout = function(_, data) flush("stdout", data) end,
        stderr = function(_, data) flush("stderr", data) end,
    }, function(result)
        vim.schedule(function()
            local tail = {}
            if remainder.stdout ~= "" then table.insert(tail, remainder.stdout) end
            if remainder.stderr ~= "" then table.insert(tail, remainder.stderr) end
            table.insert(tail, string.format("[exited with code %d]", result.code))
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, tail)
            result.stdout = accumulated.stdout
            result.stderr = accumulated.stderr
            handle_result(name, spec, cwd, result)
        end)
    end)
end

function M.run(name)
    local spec = M.commands[name]
    if not spec then
        vim.notify(string.format("quickfix_command: unknown command '%s'", name), vim.log.levels.ERROR)
        return
    end

    if spec.input then
        pick_directory(spec.input.prompt, function(dir)
            run_with_arg(name, spec, dir)
        end)
        return
    end

    run_with_arg(name, spec, nil)
end

function M.setup(opts)
    opts = opts or {}
    M.commands = vim.tbl_deep_extend("force", M.commands, opts.commands or {})

    for name, spec in pairs(opts.commands or {}) do
        if spec.keymap then
            vim.keymap.set("n", spec.keymap, function()
                M.run(name)
            end, { desc = spec.desc or ("Run " .. name) })
        end
    end
end

function M.create_user_command()
    if vim.g.quickfix_command_loaded then
        return
    end

    vim.g.quickfix_command_loaded = true

    vim.api.nvim_create_user_command("QuickfixCommand", function(args)
        M.run(args.args)
    end, {
        nargs = 1,
        complete = complete_names,
    })
end

M.parse_lines = default_parser

return M
