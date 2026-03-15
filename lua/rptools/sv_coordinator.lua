
RPTools = RPTools or {}

RPTools.Coordinator = RPTools.Coordinator or {}

local logModuleName = "Coordinator"

RPTools.Coordinator.NODE_STATE = {
    RUNNING = 1,
    ERROR = 2,
    PAUSED = 3,
}

local nodeState = {}

function RPTools.Coordinator.GetNodeRunningState(nodeId)
    return nodeState and nodeState[nodeId]
end

function RPTools.Coordinator.SetNodeRunningState(nodeId, state)
    nodeState[nodeId] = state
end

local nodePlayerState = {}

local function setAsActivated(ply, nodeId)
    if not ply:IsValid() then 
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Node " .. tostring(nodeId) .. " was activated by non-existent player " .. ply:Nick())
        return 
    end
    local steamid = ply:SteamID64()
    nodePlayerState[nodeId] = nodePlayerState[nodeId] or {}
    nodePlayerState[nodeId][steamid] = nodePlayerState[nodeId][steamid] or {}
    nodePlayerState[nodeId][ply:SteamID64()].activated = true
end

local function hasActivated(ply, nodeId)
    if not ply:IsValid() then 
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Node " .. tostring(nodeId) .. " checked for activation by non-existent player " .. ply:Nick())
        return
    end
    
    local steamid = ply:SteamID64()
    return nodePlayerState[nodeId] and nodePlayerState[nodeId][ply:SteamID64()] and nodePlayerState[nodeId][steamid].activated
end

local function recordTimestamp(ply, nodeId)
    if not ply:IsValid() then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Node " .. tostring(nodeId) .. " was activated by non-existent player " .. ply:Nick())
        return
    end
    
    local steamid = ply:SteamID64()
    nodePlayerState[nodeId] = nodePlayerState[nodeId] or {}
    nodePlayerState[nodeId][steamid] = nodePlayerState[nodeId][steamid] or {}
    nodePlayerState[nodeId][ply:SteamID64()].timestamp = CurTime()
    
end

local function getTimestamp(ply, nodeId)
    if not ply:IsValid() then 
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Node " .. tostring(nodeId) .. " checked for activation by non-existent player " .. ply:Nick())
        return
    end
    
    local steamid = ply:SteamID64()
    return nodePlayerState[nodeId] and nodePlayerState[nodeId][ply:SteamID64()] and nodePlayerState[nodeId][steamid].timestamp
end

local function activate(ply, nodeId)
    if not ply:IsValid() then 
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Node " .. tostring(nodeId) .. " was activated by non-existent player " .. ply:Nick())
        return 
    end
    local steamid = ply:SteamID64()
    nodePlayerState[nodeId] = nodePlayerState[nodeId] or {}
    nodePlayerState[nodeId][steamid] = nodePlayerState[nodeId][steamid] or {}
    nodePlayerState[nodeId][ply:SteamID64()].active = true
end

local function deactivate(ply, nodeId)
    if not ply:IsValid() then 
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Node " .. tostring(nodeId) .. " was activated by non-existent player " .. ply:Nick())
        return 
    end
    local steamid = ply:SteamID64()
    nodePlayerState[nodeId] = nodePlayerState[nodeId] or {}
    nodePlayerState[nodeId][steamid] = nodePlayerState[nodeId][steamid] or {}
    nodePlayerState[nodeId][ply:SteamID64()].active = false
end

local function isActive(ply, nodeId)
    if not ply:IsValid() then 
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Node " .. tostring(nodeId) .. " checked for activation by non-existent player " .. ply:Nick())
        return
    end
    
    local steamid = ply:SteamID64()
    return nodePlayerState[nodeId] and nodePlayerState[nodeId][ply:SteamID64()] and nodePlayerState[nodeId][steamid].active
end


function RPTools.Coordinator.GetNodeState(nodeid)
    return nodePlayerState[nodeid] or {}
end

function RPTools.Coordinator.ClearAllState()
    nodePlayerState = {}
end


local function mainLoop()
    local nodes = RPTools.NodeRegister.GetAllNodes()

    for _, node in ipairs(nodes) do
        nodeState[RPTools.Node.GetId(node)] = RPTools.Coordinator.NODE_STATE.RUNNING
    end

    for _, ply in ipairs(player.GetAll()) do
        for _, node in ipairs(nodes) do
            local nodeId = RPTools.Node.GetId(node)

            if not nodeState[nodeId] == RPTools.Coordinator.NODE_STATE.RUNNING then 
                continue
            end

            local policy = RPTools.Node.GetTriggerPolicy(node)
            
            if policy == RPTools.Node.TRIGGER_POLICY.ONE_SHOT then
                if hasActivated(ply, nodeId) then continue end
            elseif policy == RPTools.Node.TRIGGER_POLICY.MANUAL then
                continue
            elseif policy == RPTools.Node.TRIGGER_POLICY.COOLDOWN then
                local duration = RPTools.Node.GetCooldownDuration(node)
                local timestamp = getTimestamp(ply, nodeId)
                if timestamp and (CurTime() - timestamp < duration) then continue end
            end
            
            local nodeSuccess, nodeErrorMessage = pcall(function ()
                
                local conditions = RPTools.Node.GetConditions(node)
                
                local allConditionsTrue = true
                for _, condition in pairs(conditions) do
                    local source = RPTools.Condition.GetSource(condition)
                    local sourceParam = RPTools.Condition.GetSourceParameter(condition)
                    local operator = RPTools.Condition.GetOperator(condition)
                    local value = RPTools.Condition.GetValue(condition)
                    
                    local sourceValue = RPTools.Sources.GetFunction(source)(ply, node, sourceParam)
                    
                    local result = RPTools.Operators.GetFunction(operator)(sourceValue, value)
                    
                    RPTools.Logs.log(RPTools.Logs.LEVEL.DEBUG, logModuleName, 
                    "node " .. nodeId ..
                    "Condition evaluated: (" .. tostring(source) .. "(" .. tostring(sourceValue) .. "), "
                    .. tostring(operator) .. ", " .. tostring(value) .. ") = " .. tostring(result))
                    if not result then
                        allConditionsTrue = false
                        break
                    end
                end
                
                if allConditionsTrue then
                    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "node " .. nodeId .. " activated for player " .. ply:Nick())
                    
                    if not hasActivated(ply, nodeId) then setAsActivated(ply, nodeId) end
                    recordTimestamp(ply, nodeId)
                    

                    if policy ~= RPTools.Node.TRIGGER_POLICY.CONTINOUS or not isActive(ply, nodeId) then
                        local actions = RPTools.Node.GetActions(node)
                        for _, action in ipairs(actions) do
                            local params = RPTools.Actions.GetParams(action)
                            RPTools.Actions.GetFunction(RPTools.Actions.GetActionType(action))(ply, node, params)
                            activate(ply, nodeId)
                            -- Pas encore de distinction Client/Serveur
                        end
                    end
                else
                    RPTools.Logs.log(RPTools.Logs.LEVEL.DEBUG, logModuleName, "node " .. nodeId .. " was not activated for player " .. ply:Nick())
                    if isActive(ply, nodeId) then
                        deactivate(ply, nodeId)
                        -- code de desactivation ici plus tard
                    end
                end
            end)
            
            if not nodeSuccess then
                RPTools.Logs.log(RPTools.Logs.LEVEL.ERROR, logModuleName, "Node error: " .. nodeErrorMessage)
                nodeState[nodeId] = RPTools.Coordinator.NODE_STATE.ERROR
            end
        end
    end
end


function RPTools.Coordinator.Start()
    timer.Create("RPTools_Coordinator", 0.1, 0, mainLoop)
end

function RPTools.Coordinator.Stop()
    timer.Stop("RPTools_Coordinator")
end