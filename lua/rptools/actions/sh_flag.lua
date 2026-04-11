if SERVER then
  RPTools.Actions.Server.RegisterAction("flag", function(ply, node, params)
    RPTools.Blackboard.Write(ply, params.key, params.value)
  end, function(params)
    return istable(params)
      and isstring(params.key)
      and (isstring(params.value) or isbool(params.value) or RPTools.Utilities.IsNumber(params.value))
  end)
end
