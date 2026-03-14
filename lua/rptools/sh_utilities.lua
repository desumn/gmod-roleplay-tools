
RPTools = RPTools or {}

RPTools.Utilities = RPTools.Utilities or {}

function RPTools.Utilities.IsNumber(n)
    return isnumber(n) and n == n and n ~= math.huge
end

function RPTools.Utilities.MakeError(result, message)
    if not result then
        return false, message
    else
        return true, ""
    end
end

function RPTools.Utilities.AllValues(table, cond)
    for _, value in pairs(table) do
        if not cond(value) then return false end
    end
    return true
end

function RPTools.Utilities.AllKeys(table, cond)
    for key, _ in pairs(table) do
        if not cond(key) then return false end
    end
    return true
end

function RPTools.Utilities.IsSet(table, cond)
    return istable(table) and RPTools.Utilities.AllValues(table, function (val) return isbool(val) and val end )
end