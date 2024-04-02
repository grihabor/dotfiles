local function keys(tbl)
    local keyset = {}
    local n = 0

    for k, _ in pairs(tbl) do
        n = n + 1
        keyset[n] = k
    end

    return keyset
end

return { keys = keys }
