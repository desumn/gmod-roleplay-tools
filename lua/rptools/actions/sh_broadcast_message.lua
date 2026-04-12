if SERVER then
  RPTools.Actions.Server.RegisterClientAction("broadcast_message", function(params)
    return istable(params) and isstring(params.message)
  end, function(params)
    return "broadcast message: " .. params.message
  end, function (_, _, _)
    return player.GetAll()
  end)
end

if CLIENT then
  RPTools.Actions.Client.RegisterAction("broadcast_message", function(params)
    chat.AddText(params.message)
  end)
end
