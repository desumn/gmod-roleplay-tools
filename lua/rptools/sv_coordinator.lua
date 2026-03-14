
RPTools = RPTools or {}

RPTools.Coordinator = RPTools.Coordinator or {}

local logModuleName = "Coordinator"


local function mainLoop()
    local nodes = RPTools.NodeRegister.GetAllNodes()
    for _, ply in ipairs(player.GetAll()) do
        for _, node in ipairs(nodes) do
            local nodeSuccess, nodeErrorMessage = pcall(function ()
                local nodeId = RPTools.Node.GetId(node)
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

                    local actions = RPTools.Node.GetActions(node)
                    
                    for _, action in ipairs(actions) do
                        local params = RPTools.Actions.GetParams(action)
                        RPTools.Actions.GetFunction(RPTools.Actions.GetActionType(action))(ply, node, params)
                        -- Pas encore de distinction Client/Serveur
                    end
                else 
                    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "node " .. nodeId .. " was not activated for player " .. ply:Nick())
                end
            end)

            if not nodeSuccess then
                RPTools.Logs.log(RPTools.Logs.LEVEL.ERROR, logModuleName, "Node error: " .. nodeErrorMessage)

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