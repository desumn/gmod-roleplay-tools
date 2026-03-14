
RPTools = RPTools or {}

RPTools.Utilities = RPTools.Utilities or {}

function RPTools.Utilities.isnumber(n)
    return isnumber(n) and n == n and n ~= math.huge
end

function RPTools.Utilities.make_error(result, message)
    if not result then 
        return false, message
    else
        return true, ""
    end
end