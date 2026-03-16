RPTools = RPTools or {}

RPTools.Debug = RPTools.Debug or {}


local nodes = {}

local drawDebug = false


NODE_STATE = {
    RUNNING = 1,
    ERROR = 2,
    PAUSED = 3,
}

local stateColor = {
    [NODE_STATE.RUNNING] = Color(0, 140, 0),
    [NODE_STATE.ERROR] = Color(160, 60, 60),
    [NODE_STATE.PAUSED] = Color(150, 100, 100)
}

local stateText = {
    [NODE_STATE.RUNNING] = "Running",
    [NODE_STATE.ERROR] = "Error",
    [NODE_STATE.PAUSED] = "Paused"
}

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
    nodes = {}
end)

hook.Add("PostDrawOpaqueRenderables", "rptools_drawDebug", function ()
    if not drawDebug then return end

    for _, node in ipairs(nodes) do
        local position = node.position
        local distance = node.distance

        render.DrawWireframeSphere(position, 20, 15, 15, stateColor[node.state], true)

        if distance ~= 0 then
            render.DrawWireframeSphere(position, distance, 15, 15, ColorAlpha(stateColor[node.state], 60), true)
        end

        local textPos = position + Vector(0, 0, 30)
        local textAngle = (EyePos() - textPos):Angle()
        cam.Start3D2D(textPos, Angle(0, textAngle.y - 90, 90), 0.2)
        draw.SimpleText(node.id, "Default", 0, 0, color_white, TEXT_ALIGN_CENTER)
        draw.SimpleText(stateText[node.state], "Default", 0, -10, stateColor[node.state], TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end)