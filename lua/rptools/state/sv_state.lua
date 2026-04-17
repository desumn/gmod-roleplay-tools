local stateTable = {
    global = {},
    players = {}
}

---@enum RPToolsStateScope
local SCOPE = {
    PLAYER = 1,
    GLOBAL = 2,
}

---@param scope RPToolsStateScope
---@param key string
---@param context? Player
---@return any, string?
local function get(scope, key, context)
    if scope == SCOPE.GLOBAL then
        if not stateTable.global[key] then return nil, "No value for key " .. key end 
        return stateTable.global[key].value
    elseif scope == SCOPE.PLAYER then
        if not IsValid(context) then return nil, "Invalid player" end
        return (stateTable.players[key] and stateTable.players[key].values[context:SteamID64()]) or nil
    end
end

---@param scope RPToolsStateScope
---@param key string
---@param context? Player
---@return boolean, string?
local function remove(scope, key, context)
    if scope == SCOPE.GLOBAL then
        local oldValue = stateTable.global[key] and stateTable.global[key].value
        stateTable.global[key] = nil
        hook.Run("RPTools_StateValueChanged", scope, key, context, oldValue, nil)
        return true
    elseif scope == SCOPE.PLAYER then
        if not IsValid(context) then return false, "Invalid player" end
        if stateTable.players[key] then
            local oldValue = stateTable.players[key].values[context:SteamID64()]
            stateTable.players[key].values[context:SteamID64()] = nil
            hook.Run("RPTools_StateValueChanged", scope, key, context, oldValue, nil)
        end
        return true
    end
end

local function createTimer(duration, scope, key, context)
    if duration ~= nil and duration > 0 then
        local steamID = (context and context:SteamID64()) or ""
        timer.Create("rptools_" .. tostring(scope) .. "_" .. key .. tostring(steamID) .. "_autoremove", duration, 1, function () remove(scope, key, context) end)
    end
end

---@param scope RPToolsStateScope
---@param key string
---@param value any
---@param context? Player
---@param duration? number
---@return boolean, string?
local function set(scope, key, value, context, duration)
    local valueType = TypeID(value)
    if scope == SCOPE.GLOBAL then
        local oldValue = stateTable.global[key] and stateTable.global[key].value
        stateTable.global[key] = stateTable.global[key] or {
            type = valueType
        }
        if valueType == stateTable.global[key].type then
            stateTable.global[key].value = value
            hook.Run("RPTools_StateValueChanged", scope, key, context, oldValue, value)
            createTimer(duration, scope, key, context)
            return true
        else
            return false, "Invalid type for value"
        end
    elseif scope == SCOPE.PLAYER then
        if not IsValid(context) then return false, "Invalid player" end
        stateTable.players[key] = stateTable.players[key] or {
            type = valueType,
            values = {}
        }

        if valueType == stateTable.players[key].type then
            local oldValue = stateTable.players[key].values[context:SteamID64()]
            stateTable.players[key].values[context:SteamID64()] = value
            hook.Run("RPTools_StateValueChanged", scope, key, context, oldValue, value)
            createTimer(duration, scope, key, context)
            return true
        else
            return false, "Invalid type for value"
        end
    end
end

---@param name string
---@param callback fun(scope: RPToolsStateScope, key:string, context:Player?, oldValue: any, newValue: any)
local function onChange(name, callback)
    hook.Add("RPTools_StateValueChanged", "rptools_state_" .. name, callback)
end


RPTools = RPTools or {}
RPTools.State = {
    SCOPE = SCOPE,
    Get = get,
    Set = set,
    Remove = remove,
    OnValueChange = onChange,
}
