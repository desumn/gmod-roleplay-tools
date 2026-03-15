RPTools = RPTools or {}

local coordinatorStarted = false

concommand.Add("rptools_test_node", function (ply, _, _, _)
    if not ply:IsAdmin() then return end

    local cond = RPTools.Condition.Create("distance", nil, "le", 500)

    local conditions = RPTools.Condition.EmptyConditionSet()
    RPTools.Condition.AddToSet(conditions, cond)

    local action = RPTools.Actions.Create("chat_message", { message = "Je suis là!" })

    local actions = RPTools.Actions.EmptyActionSet()
    RPTools.Actions.AddToSet(actions, action)

    local pos = ply:GetPos()

    local node = RPTools.Node.Create(pos, conditions, 0, actions, RPTools.Node.TRIGGER_POLICY.ONE_SHOT, RPTools.Node.SCOPE.SINGLE_PLAYER, 0)

    RPTools.NodeRegister.RegisterNode(node)
    debugoverlay.Sphere(pos, 10, 5, Color(255, 0, 0), true)

end)


concommand.Add("rptools_test_emitter_node", function (ply, _, _, _)
    if not ply:IsAdmin() then return end

    local cond = RPTools.Condition.Create("distance", nil, "le", 500)

    local conditions = RPTools.Condition.EmptyConditionSet()
    RPTools.Condition.AddToSet(conditions, cond)

    local actionFlag = RPTools.Actions.Create("flag", {key = "test_flag", value = true})
    local action = RPTools.Actions.Create("chat_message", { message = "Le flag a été ajouté!" })

    local actions = RPTools.Actions.EmptyActionSet()
    RPTools.Actions.AddToSet(actions, action)
    RPTools.Actions.AddToSet(actions, actionFlag)

    local pos = ply:GetPos()

    local node = RPTools.Node.Create(pos, conditions, 0, actions, RPTools.Node.TRIGGER_POLICY.ONE_SHOT, RPTools.Node.SCOPE.SINGLE_PLAYER, 0)

    RPTools.NodeRegister.RegisterNode(node)
    debugoverlay.Sphere(pos, 10, 5, Color(255, 0, 0), true)

end)

concommand.Add("rptools_test_reader_node", function (ply, _, _, _)
    if not ply:IsAdmin() then return end

    local cond = RPTools.Condition.Create("distance", nil, "le", 500)
    local flag_cond = RPTools.Condition.Create("flag", "test_flag", "eq", true)

    local conditions = RPTools.Condition.EmptyConditionSet()
    RPTools.Condition.AddToSet(conditions, cond)
    RPTools.Condition.AddToSet(conditions, flag_cond)

    local action = RPTools.Actions.Create("chat_message", { message = "Je suis là car tu as le bon flag!" })

    local actions = RPTools.Actions.EmptyActionSet()
    RPTools.Actions.AddToSet(actions, action)

    local pos = ply:GetPos()

    local node = RPTools.Node.Create(pos, conditions, 0, actions, RPTools.Node.TRIGGER_POLICY.ONE_SHOT, RPTools.Node.SCOPE.SINGLE_PLAYER, 0)

    RPTools.NodeRegister.RegisterNode(node)
    debugoverlay.Sphere(pos, 10, 5, Color(255, 0, 0), true)

end)

concommand.Add("rptools_list_node", function (ply, _, _, _)
    if not ply:IsAdmin() then return end
    local nodes = RPTools.NodeRegister.GetAllNodes()
    local ids = {}
    for _, node in ipairs(nodes) do
        table.insert(ids, RPTools.Node.GetId(node))
    end
    PrintTable(ids)
end)


concommand.Add("rptools_inspect", function (ply, _, args, _)
    if not ply:IsAdmin() then return end
    if not args[1] then return end
    local node = RPTools.NodeRegister.GetNodeById(args[1])
    if not node then return end
    table.Merge(node, RPTools.Coordinator.GetNodeState(args[1]) or {})
    PrintTable(node)
end)

concommand.Add("rptools_dump_blackbaord", function (ply, _, args, _)
    if not ply:IsAdmin() then return end
    PrintTable(RPTools.Blackboard.GetAll())
end)

concommand.Add("rptools_reset", function (ply, _, args, _)
    if not ply:IsAdmin() then return end
    RPTools.NodeRegister.ClearAll()
    RPTools.Blackboard.ClearAll()
    RPTools.Coordinator.ClearAllState()
end)

concommand.Add("rptools_remove", function (ply, _, args, _)
    if not ply:IsAdmin() then return end
    if not args[1] then return end
    local node = RPTools.NodeRegister.GetNodeById(args[1])
    if not node then return end
    RPTools.NodeRegister.UnregisterNode(args[1])
end)

concommand.Add("rptools_toggle", function (ply, _, _, _)
    if not ply:IsAdmin() then return end
    if coordinatorStarted then
        RPTools.Coordinator.Stop()
    else
        RPTools.Coordinator.Start()
    end
    coordinatorStarted = not coordinatorStarted
end)
