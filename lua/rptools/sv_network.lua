
    RPTools = RPTools or {}
    RPTools.Network = RPTools.Network or {}


    local logModuleName = "Network.Server"

    util.AddNetworkString("RPTools_ClientToServer")
    util.AddNetworkString("RPTools_ServerToClient")

    local clientHandlers = {}

    function RPTools.Network.RegisterClientHandler(msgType, handler)
        if not isfunction(handler) then return end
        local msgTypeValid, msgTypeErrorMessage = RPTools.Network.ValidateMessageType(msgType)
        if not msgTypeValid then
            RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, msgTypeErrorMessage)
            return
        end

        clientHandlers[msgType] = handler

    end

    net.Receive("RPTools_ClientToServer", function (_, ply)
        local msgType = RPTools.Network.ReadMessageType()
        local msgName = RPTools.Network.FormatMessageType(msgType)

        if not clientHandlers[msgType] then
            RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "No handler registered for message type " .. msgName)
            return
        end

        local handlerSuccess, handlerErrorMessage = pcall(function ()
            RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Receiving message from client to server: " .. msgName) 
            clientHandlers[msgType](ply)
        end)

        if not handlerSuccess then 
            RPTools.Logs.log(RPTools.Logs.LEVEL.ERROR, logModuleName, "Server receiving from client handler " .. msgName .. " failed " .. handlerErrorMessage ) 
        end

    end)

    function RPTools.Network.SendToClients(clients, msgType, sender)
        if not clients then return end
        if not isfunction(sender) then return end
        local msgTypeValid, msgTypeErrorMessage = RPTools.Network.ValidateMessageType(msgType)
        if not msgTypeValid then
            RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, msgTypeErrorMessage)
            return
        end

        net.Start("RPTools_ServerToClient")
        RPTools.Network.WriteMessageType(msgType)
        sender()
        net.Send(clients)
    end

    function RPTools.Network.SendToAdmins(msgType, sender)

        local admins = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsAdmin() then table.insert(admins, ply) end
        end

        if #admins > 0 then
            RPTools.Network.SendToClients(admins, msgType, sender)
        end
    end

    function RPTools.Network.SendToPlayer(ply, msgType, sender)
        if not ply:IsValid() then return end

        RPTools.Network.SendToClients(ply, msgType, sender)
    end

    function RPTools.Network.SendToAll(msgType, sender)
        RPTools.Network.SendToClients(player.GetAll(), msgType, sender)
    end

    hook.Add("PlayerInitialSpawn", "rptools_reconnect_sync" , function (ply)
        return
    end)
