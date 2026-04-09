RPTools = RPTools or {}
RPTools.Commands = RPTools.Commands or {}


function RPTools.Commands.requireAdmin(ply)
    if not ply:IsAdmin() then
        print("Permission denied")
        return
    else
        return true
    end
end

local coordinatorStarted = false

concommand.Add("rptools_list_node", function (ply, _, _, _)
    if not RPTools.Commands.requireAdmin(ply) then return end
    local nodes = RPTools.NodeRegister.GetAllNodes()
    local ids = {}
    for _, node in ipairs(nodes) do
        table.insert(ids, RPTools.Node.GetId(node))
    end
    PrintTable(ids)
end)


concommand.Add("rptools_inspect", function (ply, _, args, _)
    if not RPTools.Commands.requireAdmin(ply) then return end
    if not args[1] then return end
    local node = RPTools.NodeRegister.GetNodeById(args[1])
    if not node then return end
    table.Merge(node, RPTools.Coordinator.GetNodeState(args[1]) or {})
    PrintTable(node)
end)


concommand.Add("rptools_flag", function (ply, _, args, _)
    if not RPTools.Commands.requireAdmin(ply) then return end
    local playerName = args[1]
    if not playerName then return end
    local flag = args[2]
    if not flag then return end

    for _, ply_ in ipairs(RPTools.Utilities.FindPlayerByName(playerName)) do
        print("Added flag " .. flag .. " to " .. ply_:Nick())
        RPTools.Blackboard.Write(ply_, flag, true)
    end
end)

concommand.Add("rptools_unflag", function (ply, _, args, _)
    if not RPTools.Commands.requireAdmin(ply) then return end
    local playerName = args[1]
    if not playerName then return end
    local flag = args[2]
    if not flag then return end

    for _, ply_ in ipairs(RPTools.Utilities.FindPlayerByName(playerName)) do
        print("Removed flag " .. flag .. " from " .. ply_:Nick())
        RPTools.Blackboard.Write(ply_, flag, nil)
    end
end)

concommand.Add("rptools_dump_blackboard", function (ply, _, args, _)
    if not RPTools.Commands.requireAdmin(ply) then return end
    PrintTable(RPTools.Blackboard.GetAll())
end)

concommand.Add("rptools_reset", function (ply, _, args, _)
    if not RPTools.Commands.requireAdmin(ply) then return end
    RPTools.NodeRegister.ClearAll()
    RPTools.Blackboard.ClearAll()
    RPTools.Coordinator.ClearAllState()
end)

concommand.Add("rptools_remove", function (ply, _, args, _)
    if not RPTools.Commands.requireAdmin(ply) then return end
    if not args[1] then return end
    local node = RPTools.NodeRegister.GetNodeById(args[1])
    if not node then return end
    RPTools.NodeRegister.UnregisterNode(args[1])
end)

concommand.Add("rptools_pause_node", function (ply, _, args, _)
    if not RPTools.Commands.requireAdmin(ply) then return end
    if not args[1] then return end
    local node = RPTools.NodeRegister.GetNodeById(args[1])
    if not node then return end
    RPTools.Coordinator.SetNodeRunningState(args[1], RPTools.Coordinator.NODE_STATE.PAUSED)
end)


concommand.Add("rptools_unpause_node", function (ply, _, args, _)
    if not RPTools.Commands.requireAdmin(ply) then return end
    if not args[1] then return end
    local node = RPTools.NodeRegister.GetNodeById(args[1])
    if not node then return end
    RPTools.Coordinator.SetNodeRunningState(args[1], RPTools.Coordinator.NODE_STATE.RUNNING)
end)

concommand.Add("rptools_toggle", function (ply, _, _, _)
    if not RPTools.Commands.requireAdmin(ply) then return end
    if coordinatorStarted then
        RPTools.Coordinator.Stop()
    else
        RPTools.Coordinator.Start()
    end
    coordinatorStarted = not coordinatorStarted
end)
