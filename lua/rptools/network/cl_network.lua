RPTools = RPTools or {}
RPTools.Network = RPTools.Network or {}

local logModuleName = "Network.Client"

local serverHandlers = {}

---@param msgType RPToolsMsgType
---@param handler fun()
function RPTools.Network.OnServerMessage(msgType, handler)
  if not isfunction(handler) then
    return
  end
  local msgTypeValid, msgTypeErrorMessage = RPTools.Network.ValidateMessageType(msgType)
  if not msgTypeValid then
    RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, msgTypeErrorMessage)
    return
  end

  serverHandlers[msgType] = handler
end

net.Receive("RPTools_ServerToClient", function()
  local msgType = RPTools.Network.ReadMessageType()
  local msgName = RPTools.Network.FormatMessageType(msgType)

  if not serverHandlers[msgType] then
    RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "No handler registered for message type " .. msgName)
    return
  end

  local handlerSuccess, handlerErrorMessage = pcall(function()
    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Receiving message from server to client: " .. msgName)
    serverHandlers[msgType]()
  end)

  if not handlerSuccess then
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.ERROR,
      logModuleName,
      "Client receiving from server handler " .. msgName .. " failed " .. handlerErrorMessage
    )
  end
end)

---@param msgType RPToolsMsgType
---@param sender fun()
function RPTools.Network.SendToServer(msgType, sender)
  if not isfunction(sender) then
    return
  end
  local msgTypeValid, msgTypeErrorMessage = RPTools.Network.ValidateMessageType(msgType)
  if not msgTypeValid then
    RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, msgTypeErrorMessage)
    return
  end

  net.Start("RPTools_ClientToServer")
  RPTools.Network.WriteMessageType(msgType)
  sender()
  net.SendToServer()
end
