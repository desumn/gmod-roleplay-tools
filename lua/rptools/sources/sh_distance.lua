if SERVER then
  RPTools.Sources.Server.RegisterSource("distance", function(ply, node, param)
    return ply:GetPos():Distance(node.position)
  end, function(param)
    return param == nil
  end, function(_)
    return "distance"
  end)
end
