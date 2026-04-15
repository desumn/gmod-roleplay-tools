if SERVER then
  RPTools.Actions.Server.RegisterAction("flag", function(ply, node, params)
    RPTools.Blackboard.Write(ply, RPTools.Blackboard.Key.Flag(params.key), params.value)
  end, function(params)
    return istable(params) and isstring(params.key) and (isstring(params.value) or isbool(params.value))
  end, function(params)
    return "flag " .. params.key .. " = " .. tostring(params.value)
  end)
end
