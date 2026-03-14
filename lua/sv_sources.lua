RPTools = RPTools or {}

RPTools.Sources = RPTools.Sources or {}

local sourceFunctions = {
    distance = function(player, node, params)
        RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, "Init", "distance source not implemented")
    end,
    flag = function(player, node, params)
        RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, "Init", "flag source not implemented")
    end
}


function RPTools.Sources.ValidateSource(source) 
    return RPTools.Utilities.MakeError(sourceFunctions[source] ~= nil, "Invalid source: " .. tostring(source))
end

function RPTools.Sources.GetFunction(source)
    local operatorValid, operatorErrorMessage = RPTools.Sources.ValidateSource(source)

    if operatorValid then
        return sourceFunctions[source], nil
    else
        return nil, operatorErrorMessage
    end
end

local validators = {
    distance = function (params) return params == nil end,
    flag = function (params) return isstring(params) end
}

local expectedTypes = {
    distance = "none",
    flag = "key = string"
}

function RPTools.Sources.ValidateParameter(source, param)
    return RPTools.Utilities.MakeError(validators[source](param), "Invalid params for source " .. tostring(source) .. "(" 
                                        .. expectedTypes[source] ..  ")" .. ": " .. tostring(param))
end