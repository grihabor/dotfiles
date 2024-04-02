local function map(arr, f)
    local result = {}
    for k, v in pairs(arr) do
        result[k] = f(v)
    end
    return result
end
return { map = map }
