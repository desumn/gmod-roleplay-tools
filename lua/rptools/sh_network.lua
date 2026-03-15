RPTools = RPTools or {}

RPTools.Network = RPTools.Network or {}

RPTools.Network.MSG_TYPE = {
    DEBUG_SYNC = 1,
    NODE_SYNC = 2,
    CLIENT_RESULT = 3,
    FULL_SYNC = 4,
}

local msgTypeNames = {
    [RPTools.Network.MSG_TYPE.DEBUG_SYNC] = "debug sync",
    [RPTools.Network.MSG_TYPE.NODE_SYNC] = "node sync",
    [RPTools.Network.MSG_TYPE.CLIENT_RESULT] = "client sync",
    [RPTools.Network.MSG_TYPE.FULL_SYNC] = "full sync"
}


function RPTools.Network.ValidateMessageType(msgType)
    return RPTools.Utilities.MakeError(RPTools.Utilities.IsNumber(msgType) and
                                       RPTools.Network.MSG_TYPE[msgType] ~= nil, "Invalid message type" .. tostring(msgType))
end

function RPTools.Network.WriteMessageType(msgType)
    return net.WriteUInt(msgType, 4)
end

function RPTools.Network.ReadMessageType()
    return net.ReadUInt(4)
end

function RPTools.Network.FormatMessageType(msgType)
    return msgTypeNames[msgType]
end