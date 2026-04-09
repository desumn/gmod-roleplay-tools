RPTools = RPTools or {}

RPTools.Debug = RPTools.Debug or {}

surface.CreateFont("RPTools_DebugText", {
  font = "Roboto",
  size = 70,
  weight = 800,
  antialias = true,
  extended = true,
})

local nodes = {}

local drawDebug = false

function RPTools.Debug.ReadDebugNode()
  local id = net.ReadString()
  local position = net.ReadVector()
  local distance = net.ReadUInt(16)
  local state = net.ReadUInt(3)
  local node = { id = id, position = position, distance = distance, state = state }
  return node
end

function RPTools.Debug.GetDebugNodes()
  return nodes
end

RPTools.Network.RegisterServerHandler(RPTools.Network.MSG_TYPE.DEBUG_SYNC, function()
  local nodeCount = net.ReadUInt(12)
  nodes = {}
  for i = 1, nodeCount do
    nodes[i] = RPTools.Debug.ReadDebugNode()
  end
  drawDebug = true
end)

concommand.Add("rptools_toggle_debug", function()
  if not LocalPlayer():IsAdmin() then
    return
  end
  RPTools.Network.SendToServer(RPTools.Network.MSG_TYPE.DEBUG_SYNC, function() end)
  if drawDebug then
    drawDebug = false
    nodes = {}
  else
    drawDebug = true
  end
end)

hook.Add("PostDrawTranslucentRenderables", "rptools_drawDebug", function()
  if not drawDebug then
    return
  end

  for _, node in ipairs(nodes) do
    local position = node.position
    local distance = node.distance

    render.DrawWireframeSphere(position, 20, 15, 15, RPTools.Coordinator.stateColor[node.state], true)

    if distance ~= 0 then
      render.DrawWireframeSphere(
        position,
        distance,
        15,
        15,
        ColorAlpha(RPTools.Coordinator.stateColor[node.state], 60),
        true
      )
    end

    local textPos = position + Vector(0, 0, 5)

    local ang = LocalPlayer():EyeAngles()

    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(textPos, ang, 0.1)

    draw.SimpleText(node.id, "RPTools_DebugText", 0, 0, color_white, TEXT_ALIGN_CENTER)
    draw.SimpleText(
      RPTools.Coordinator.stateText[node.state],
      "RPTools_DebugText",
      0,
      70,
      RPTools.Coordinator.stateColor[node.state],
      TEXT_ALIGN_CENTER
    ) -- Y ajusté

    cam.End3D2D()
  end
end)
