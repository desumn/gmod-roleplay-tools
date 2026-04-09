RPTools = RPTools or {}

RPTools.Network = RPTools.Network or {}

---@enum RPToolsMsgType
RPTools.Network.MSG_TYPE = {
  DEBUG_SYNC = 1,
  NODE_SYNC = 2,
  TEMPLATE_SYNC = 3,
  CLIENT_RESULT = 4,
  FULL_SYNC = 5,
  CREATE_FROM_TEMPLATE = 6,
  DELETE_NODE = 7,
}

local msgTypeNames = {
  [RPTools.Network.MSG_TYPE.DEBUG_SYNC] = "debug sync",
  [RPTools.Network.MSG_TYPE.NODE_SYNC] = "node sync",
  [RPTools.Network.MSG_TYPE.TEMPLATE_SYNC] = "template sync",
  [RPTools.Network.MSG_TYPE.CLIENT_RESULT] = "client sync",
  [RPTools.Network.MSG_TYPE.FULL_SYNC] = "full sync",
  [RPTools.Network.MSG_TYPE.CREATE_FROM_TEMPLATE] = "create from template",
  [RPTools.Network.MSG_TYPE.DELETE_NODE] = "delete node",
}

---@param msgType RPToolsMsgType
---@return boolean, string
function RPTools.Network.ValidateMessageType(msgType)
  return RPTools.Utilities.MakeError(
    RPTools.Utilities.IsNumber(msgType) and msgType >= 1 and msgType <= 7,
    "Invalid message type" .. tostring(msgType)
  )
end

---@param msgType RPToolsMsgType
function RPTools.Network.WriteMessageType(msgType)
  return net.WriteUInt(msgType, 4)
end

---@return RPToolsMsgType
function RPTools.Network.ReadMessageType()
  return net.ReadUInt(4)
end

---@param msgType RPToolsMsgType
---@return string
function RPTools.Network.FormatMessageType(msgType)
  return msgTypeNames[msgType]
end
