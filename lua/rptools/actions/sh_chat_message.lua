if SERVER then
  RPTools.Actions.Server.RegisterClientAction("chat_message", function(params)
    return istable(params) and isstring(params.message)
  end, function(params)
    return "chat message: " .. params.message
  end)
end

if CLIENT then
  RPTools.Actions.Client.RegisterAction("chat_message", function(params)
    chat.AddText(Color(200, 220, 240), params.message)
  end)
end
