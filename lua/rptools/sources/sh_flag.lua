if SERVER then
  RPTools.Sources.Server.RegisterSource("flag", function(ply, node, param)
    return RPTools.Blackboard.Read(ply, param)
  end, function(param)
    return isstring(param)
  end)
end
