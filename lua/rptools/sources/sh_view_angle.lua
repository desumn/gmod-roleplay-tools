if SERVER then
    RPTools.Sources.Server.RegisterSource("view_angle", function(ply, node, param)
        local eyeDir = ply:EyeAngles():Forward()
        local toNode = (node.position - ply:EyePos()):GetNormalized()
        local dot = eyeDir:Dot(toNode)
        local angle = math.deg(math.acos(dot))
        return angle
    end, function(param)
        return param == nil
    end)
end
