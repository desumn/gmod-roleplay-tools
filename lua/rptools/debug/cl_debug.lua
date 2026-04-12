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
  local policy = net.ReadUInt(3)
  local policyText = net.ReadString()
  local position = net.ReadVector()
  local distance = net.ReadUInt(16)
  local state = net.ReadUInt(3)
  local conditionsDesc = net.ReadTable(true)
  local actionsDesc = net.ReadTable(true)

  local node = {
    id = id,
    triggerPolicy = policy,
    triggerPolicyText = policyText,
    position = position,
    distance = distance,
    state = state,
    conditionsDesc = conditionsDesc,
    actionsDesc = actionsDesc,
  }
  return node
end

function RPTools.Debug.GetDebugNodes()
  return nodes
end

local directions = {
  Vector(0, 0, -1),
  Vector(1, 0, 0),
  Vector(-1, 0, 0),
  Vector(0, 1, 0),
  Vector(0, -1, 0),
  Vector(0, 0, 1),
}

local function inferNormal(pos)
  for _, dir in ipairs(directions) do
    local tr = util.TraceLine({
      start = pos - (dir * 2),
      endpos = pos + (dir * 15),
    })

    if tr.Hit and not tr.StartSolid then
      return tr.HitNormal
    end
  end
  return Vector(0, 0, 1)
end

local nodeNormal = {}

RPTools.Network.OnServerMessage(RPTools.Network.MSG_TYPE.DEBUG_SYNC, function()
  local nodeCount = net.ReadUInt(12)
  nodes = {}
  for i = 1, nodeCount do
    nodes[i] = RPTools.Debug.ReadDebugNode()
    if not nodeNormal[nodes[i].id] then
      nodeNormal[nodes[i].id] = inferNormal(nodes[i].position)
    end
  end
  drawDebug = true
end)

concommand.Add("rptools_toggle_debug", function()
  if not LocalPlayer():IsAdmin() then
    return
  end
  RPTools.Network.SendToServer(RPTools.Network.MSG_TYPE.DEBUG_TOGGLE, function() end)
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
    local normal = nodeNormal[node.id]
    local offsetVector = normal * 100

    local radius = node.distance

    local color = RPTools.Coordinator.stateColor[node.state] or color_white
    render.SetMaterial(Material("sprites/light_glow02_add"))
    render.DrawBeam(position, position + offsetVector, 10, 0, 1, ColorAlpha(color, 100))
    render.DrawSprite(position, 48, 48, color)

    local ang1 = normal:Angle()
    ang1:RotateAroundAxis(ang1:Right(), -90)

    cam.Start3D2D(position + (normal * 1), ang1, 1)
    surface.DrawCircle(0, 0, radius, 0, 255, 0, 50)
    cam.End3D2D()

    local ang2 = normal:Angle()
    ang2:RotateAroundAxis(ang2:Forward(), 90)

    cam.Start3D2D(position + (normal * 1), ang2, 1)
    surface.DrawCircle(0, 0, radius, 0, 255, 0, 50)
    cam.End3D2D()
  end
end)
