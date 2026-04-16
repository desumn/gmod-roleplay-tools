
local logModuleName = "Dispatcher"

hook.Add("RPTools_NodeActivated", "rptools_dispatch_activated", function(nodeId, node, players)
    local actionsSuccess, actionsError = pcall(function () 
        for _, action in ipairs(node.actions) do
            local actionFunc = RPTools.Actions.Server.GetFunction(action.actionType)
            actionFunc(players, node, action.params)
        end
    end)

    if not actionsSuccess then
      RPTools.Coordinator.SetNodeRunningState(nodeId, RPTools.Coordinator.NODE_STATE.ERROR)
      RPTools.Logs.log(
        RPTools.Logs.LEVEL.ERROR,
        logModuleName,
        node.id .. " action evaluation failed: " .. actionsError
      )
    end
end)