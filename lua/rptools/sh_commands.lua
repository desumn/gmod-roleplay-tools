RPTools = RPTools or {}

local coordinatorStarted = false

concommand.Add("rptools_test_node", function (ply, _, _, _)
    if not ply:IsAdmin() then return end

    local cond = RPTools.Condition.Create("distance", "le", 500)

    local conditions = RPTools.Condition.EmptyConditionSet()
    RPTools.Condition.AddToSet(conditions, cond)

    local action = RPTools.Actions.Create("chat_message", { message = "Je suis là!" })

    local actions = RPTools.Actions.EmptyActionSet()
    RPTools.Actions.AddToSet(actions, action)

    local pos = ply:GetPos()

    local node = RPTools.Node.Create(pos, conditions, 0, actions, RPTools.Node.TRIGGER_POLICY.COOLDOWN, RPTools.Node.SCOPE.SINGLE_PLAYER, 0)

    RPTools.NodeRegister.RegisterNode(node)
    debugoverlay.Sphere(pos, 10, 5, Color(255, 0, 0), true)

end)

concommand.Add("rptools_list_node", function (ply, _, _, _)
    if not ply:IsAdmin() then return end
    PrintTable(RPTools.NodeRegister.GetAllNodes())
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
