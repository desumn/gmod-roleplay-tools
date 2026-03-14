
RPTools = RPTools or {}
RPTools.Actions = RPTools.Actions or {}


local actionFunctions = {
    chat_message = function(ply, _, params)
        ply:ChatPrint(params.message)
    end,
    flag = function(ply, _, params)
        RPTools.Blackboard.Write(ply, params.key, params.value)
    end
}

function RPTools.Actions.GetFunction(actionType)
    return actionFunctions[actionType]
end

local function validateType(actionType)
    return RPTools.Utilities.MakeError(actionFunctions[actionType] ~= nil, "Invalid action type: " .. tostring(actionType))
end

RPTools.Actions.SIDE = {
    SERVER = 1,
    CLIENT = 2,
}

local sides = {
    chat_message = RPTools.Actions.SIDE.SERVER,
    flag = RPTools.Actions.SIDE.SERVER,
}

local validators = {
    chat_message = function (params) return istable(params) and isstring(params.message) and RPTools.Utilities.AllKeys(params, function (key) return key == "message" end) end,
    flag = function (params)
            return istable(params) and isstring(params.key) and (isstring(params.value) or isbool(params.value) or RPTools.Utilities.IsNumber(params.value))
                    and RPTools.Utilities.AllKeys(params, function (key) return key == "key" or key == "value" end)
    end
}

-- Table purement documentaire
local expectedTypes = {
    chat_message = "message = string",
    flag = "key = string, value = string OR bool OR number"
}

-- On assume que type est valide, comme dnas Operators.ValidateValue
local function validateParams(actionType, params)
    return RPTools.Utilities.MakeError(validators[actionType](params), "Invalid params for type" .. tostring(actionType) .. "(" 
                                        .. expectedTypes[actionType] ..  ")" .. ": " .. tostring(params))
end

function RPTools.Actions.ValidateAction(action)
    local typeValid, typeErrorMessage = validateType(action.actionType)

    if not typeValid then
        return false, typeErrorMessage
    end

    local paramsValid, paramsErrorMessage = validateParams(action.actionType, action.params)

    if not paramsValid then
        return false, paramsErrorMessage
    end

    return true, nil

end

function RPTools.Actions.EmptyActionSet()
    return {}
end

function RPTools.Actions.AddToSet(set, action)
    table.insert(set, action)
end

function RPTools.Actions.Create(actionType, params)
    local action = { actionType = actionType, params = params}
    local actionValid, errorMessage = RPTools.Actions.ValidateAction(action)

    if actionValid then
        return action, nil
    else 
        return nil, errorMessage
    end
end

function RPTools.Actions.GetActionType(action)
    return action.actionType
end

function RPTools.Actions.GetSide(action)
    return sides[action.actionType]
end

function RPTools.Actions.GetParams(action)
    return table.Copy(action.params)
end


function RPTools.Actions.ValidateActionsSet(actions)

    local allActionsValid = true
    local accumulatedErrorMessage = ""

    for _, action in ipairs(actions) do
        local actionValid, conditionErrorMessage = RPTools.Actions.ValidateAction(action)
        allActionsValid = actionValid and allActionsValid
        if not actionValid then
            accumulatedErrorMessage = conditionErrorMessage .. ", " .. accumulatedErrorMessage
        end
    end

    if not allActionsValid then
        return false, accumulatedErrorMessage
    else
        return true, nil
    end
end

