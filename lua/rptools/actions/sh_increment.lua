if SERVER then
  RPTools.Actions.Server.RegisterAction("increment", function(ply, node, params)
    local key = RPTools.Blackboard.Key.Counter(params.key)
    RPTools.Blackboard.Increment(ply, key, params.value)
  end, function(params)
    return istable(params) and isstring(params.key) and RPTools.Utilities.IsNumber(params.value)
  end, function(params)
    return "flag " .. params.key .. " += " .. params.value
  end)
end
