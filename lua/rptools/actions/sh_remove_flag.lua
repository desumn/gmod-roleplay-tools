if SERVER then
  RPTools.Actions.Server.RegisterAction("remove_flag", function(ply, node, params)
    RPTools.Blackboard.Write(ply, RPTools.Blackboard.Key.Flag(params.key), nil)
  end, function(params)
    return istable(params)
      and isstring(params.key)
  end, function(params)
    return "Remove flag " .. params.key
  end)
end
