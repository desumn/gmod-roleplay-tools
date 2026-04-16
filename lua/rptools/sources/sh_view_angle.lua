if SERVER then
  RPTools.Sources.Server.RegisterSource("view_angle", function(ply, node, param)
    local eyeDir = ply:EyeAngles():Forward()
    local toNode = (RPTools.Node.GetPosition(node) - ply:EyePos()):GetNormalized()
    local dot = eyeDir:Dot(toNode)
    local angle = math.deg(math.acos(dot))
    return angle
  end, function(param)
    return param == nil
  end, function(_)
    return "view angle (in deg)"
  end)
end
