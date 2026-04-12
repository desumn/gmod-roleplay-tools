if SERVER then
  RPTools.Sources.Server.RegisterSource("flag", function(ply, node, param)
    return RPTools.Blackboard.Read(ply, RPTools.Blackboard.Key.Flag(param))
  end, function(param)
    return isstring(param)
  end, function(param)
    return "flag " .. param
  end)
end
