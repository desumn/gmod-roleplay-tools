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

RPTools.Network.OnServerMessage(RPTools.Network.MSG_TYPE.DEBUG_ADD, function()
  local nodeCount = net.ReadUInt(12)
  for i = 1, nodeCount do
    local node = RPTools.Debug.ReadDebugNode()
    table.insert(nodes, node)
    if not nodeNormal[node.id] then
      nodeNormal[node.id] = inferNormal(node.position)
    end
  end
end)

RPTools.Network.OnServerMessage(RPTools.Network.MSG_TYPE.DEBUG_REMOVE, function()
  local nodeId = net.ReadString()
  
  local idxToRemove = nil
  for idx, node in ipairs(nodes) do
    if node.id == nodeId then
      idxToRemove = idx
      break
    end
  end
  
  if idxToRemove == nil then
    return
  end
  
  table.remove(nodes, idxToRemove)
end)

concommand.Add("rptools_toggle_debug", function()
  if not LocalPlayer():IsAdmin() then
    return
  end
  RPTools.Network.SendToServer(RPTools.Network.MSG_TYPE.DEBUG_TOGGLE, function() end)
end)

hook.Add("PostDrawTranslucentRenderables", "rptools_drawDebug", function()
  if not LocalPlayer():GetNW2Bool("rptools_debug", false) then
    return
  end
  
  for _, node in ipairs(nodes) do
    local position = node.position
    local normal = nodeNormal[node.id]
    local offsetVector = normal * 150
    
    local radius = node.distance
    
    local color = RPTools.Coordinator.stateColor[node.state] or color_white
    render.SetMaterial(Material("sprites/sent_ball"))
    render.DrawSprite(position, 24, 24, ColorAlpha(color_black, 180))
    render.SetMaterial(Material("sprites/light_glow02_add"))
    render.DrawBeam(position, position + offsetVector, 12, 0, 1, ColorAlpha(color, 100))
    render.DrawSprite(position, 48, 48, color)
    
    local beamMaterial = Material("trails/laser")
    render.SetMaterial(beamMaterial)
    local segments = 64
    render.StartBeam(segments + 1)
    for i = 0, segments do
      local a = (i / segments) * math.pi * 2
      local p = position + Vector(math.cos(a) * radius, math.sin(a) * radius, 2)
      render.AddBeam(p, 16, i / segments, color)
    end
    render.EndBeam()
    
    render.StartBeam(segments + 1)
    for i = 0, segments do
      local a = (i / segments) * math.pi * 2
      local p = position + Vector(math.cos(a) * radius, 0, math.sin(a) * radius)
      render.AddBeam(p, 16, i / segments, color)
    end
    render.EndBeam()
  end
end)
