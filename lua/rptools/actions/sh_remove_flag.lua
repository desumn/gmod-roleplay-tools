if SERVER then
  RPTools.Actions.Server.RegisterAction("remove_flag", function(plys, node, params)
    for _, ply in ipairs(plys) do
      RPTools.Blackboard.Write(ply, RPTools.Blackboard.Key.Flag(params.key), nil)
    end
  end, function(params)
    return istable(params) and isstring(params.key)
  end, function(params)
    return "Remove flag " .. params.key
  end)
end
