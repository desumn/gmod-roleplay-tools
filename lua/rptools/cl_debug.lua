RPTools = RPTools or {}

RPTools.Debug = RPTools.Debug or {}


local nodes = {}

local drawDebug = false

function RPTools.Debug.ReadDebugNode()
    local id = net.ReadString()
    local position = net.ReadVector()
    local distance = net.ReadUInt(16)
    local state = net.ReadUInt(3)
    local node = {id = id, position = position, distance = distance, state = state}
    return node
end

RPTools.Network.RegisterServerHandler(RPTools.Network.MSG_TYPE.DEBUG_SYNC, function()
    local nodeCount = net.ReadUInt(12)
    nodes = {}
    for i = 1, nodeCount do
        nodes[i] = RPTools.Debug.ReadDebugNode()
    end
    drawDebug = true
end)

concommand.Add("rptools_toggle_draw_debug", function ()
    drawDebug = not drawDebug
end)

hook.Add("PostDrawOpaqueRenderables", "rptools_drawDebug", function ()
    return
end)