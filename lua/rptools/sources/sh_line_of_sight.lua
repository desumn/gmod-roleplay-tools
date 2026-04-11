if SERVER then
    RPTools.Sources.Server.RegisterSource("line_of_sight", function(ply, node, param)
        local trace = util.TraceLine({
            start = ply:EyePos(),
            endpos = node.position,
            filter = ply
        })
        return not trace.Hit
    end, function(param)
        return param == nil
    end)
end
