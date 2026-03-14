RPTools = RPTools or {}

local logModuleName = "Blackboard"

RPTools.Blackboard = RPTools.Blackboard or {}

local blackboard = {}

function RPTools.Blackboard.Read(ply, key)
    if not ply or not ply:IsValid() then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Tried to read in blackboard on invalid player: " .. tostring(ply) .. " with key: " .. tostring(key))
        return
    end

    if not isstring(key) then 
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, 
                            "Tried to read non string key: " .. tostring(key) .. " for player " .. tostring(ply:Nick()))
        return 
    end

    local steamid = ply:SteamID64()

    blackboard[steamid] = blackboard[steamid] or {}
    return blackboard[steamid][key]
end

function RPTools.Blackboard.Write(ply, key, value)
    if not ply or not ply:IsValid() then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Tried to write in blackboard on invalid player: " .. tostring(ply) .. " with key: " .. tostring(key))
        return
    end

    if not isstring(key) then 
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, 
                            "Tried to write non string key: " .. tostring(key) .. " for player " .. tostring(ply:Nick()) .. " with value: " .. tostring(value))
        return 
    end

    local steamid = ply:SteamID64()

    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Set (" .. key .. ", " .. tostring(value)  .. ") in blackboard  for player " .. tostring(ply:Nick()))
    
    blackboard[steamid] = blackboard[steamid] or {}
    blackboard[steamid][key] = value
end

function RPTools.Blackboard.Increment(ply, key, value)
    local incrementValue = value or 1

    if not ply or not ply:IsValid() then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Tried to increment value in blackboard on invalid player: " .. tostring(ply) .. " with key: " .. tostring(key))
        return
    end

    if not isstring(key) then 
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, 
                            "Tried to increment non string key: " .. tostring(key) .. " for player " .. tostring(ply:Nick()) .. " with increment value: " .. tostring(incrementValue))
        return 
    end

    local steamid = ply:SteamID64()

    blackboard[steamid] = blackboard[steamid] or {}
    local oldValue = blackboard[steamid][key] or 0


    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Incremented value at key " .. key .. " from " .. tostring(oldValue)  .. " by " ..  tostring(incrementValue) ..
                        "in blackboard  for player " .. tostring(ply:Nick()))
    
    blackboard[steamid][key] = oldValue + incrementValue
end

function RPTools.Blackboard.ClearForPlayer(ply)
    if not ply or not ply:IsValid() then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Tried to clear blackboard on invalid player: " .. tostring(ply))
        return
    end
    local steamid = ply:SteamID64()


    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Cleared blackboard for player: " .. tostring(ply:Nick()))
    blackboard[steamid] = {}
end

function RPTools.Blackboard.ClearAll()
    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Cleared all blackboard")
    blackboard = {}
end

function RPTools.Blackboard.serialize()
    return util.TableToJSON(blackboard)
end

function RPTools.Blackboard.deserialize(blackboard_json)
    local newBlackboard = util.JSONToTable(blackboard_json)
    if not newBlackboard then 
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Failed to deserialize blackboard")
        return
    end

    blackboard = newBlackboard
end