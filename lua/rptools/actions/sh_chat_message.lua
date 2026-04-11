if SERVER then
    RPTools.Actions.Server.RegisterClientAction("chat_message", function(params)
        return istable(params) and isstring(params.message)
    end)
end

if CLIENT then
    RPTools.Actions.Client.RegisterAction("chat_message", function(params)
        chat.AddText(params.message)
    end)
end