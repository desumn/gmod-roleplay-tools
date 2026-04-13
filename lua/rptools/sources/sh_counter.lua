if SERVER then
  RPTools.Sources.Server.RegisterSource("counter", function(ply, node, param)
    return RPTools.Blackboard.Read(ply, RPTools.Blackboard.Key.Counter(param))
  end, function(param)
    return isstring(param)
  end, function(param)
    return "counter " .. param
  end)
end
