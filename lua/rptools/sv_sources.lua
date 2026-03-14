RPTools = RPTools or {}

RPTools.Sources = RPTools.Sources or {}

local sourceFunctions = {
    distance = function(ply, node, _)
        return ply:GetPos():distance(RPTools.Node.GetPosition(node))
    end,
    flag = function(ply, node, param)
        return RPTools.Blackboard.Read(ply, param)
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