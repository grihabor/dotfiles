local M = {
    commands = {},
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

local function normalize_command(command)
    if type(command) == "function" then
        command = command()
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
    if filename == "" then
        return nil
    end

    if vim.fs.isabs(filename) then
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
        vim.cmd("copen")
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

function M.run(name)
    local spec = M.commands[name]
    if not spec then
        vim.notify(string.format("quickfix_command: unknown command '%s'", name), vim.log.levels.ERROR)
        return
    end

    local ok, command = pcall(normalize_command, spec.command)
    if not ok then
        vim.notify(command, vim.log.levels.ERROR)
        return
    end

    local cwd = normalize_cwd(spec.cwd)
    local title = spec.title or name

    vim.notify(table.concat(command, " "), vim.log.levels.INFO)

    vim.system(command, { cwd = cwd, text = true }, function(result)
        vim.schedule(function()
            handle_result(name, spec, cwd, result)
        end)
    end)
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

return M
