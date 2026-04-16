local zones = {}
local noZones = {}

hook.Add("RPTools_NodeCreated", "rptools_create_zone", function(id, node)
  local conditions = RPTools.Node.GetConditions(node)
  local distances = {}
  for _, condition in ipairs(conditions) do
    local source = RPTools.Condition.GetSource(condition)
    if source ~= "distance" then
      continue
    end
    local operator = RPTools.Condition.GetOperator(condition)
    if operator ~= "le" and operator ~= "lt" then
      continue
    end
    table.insert(distances, RPTools.Condition.GetValue(condition))
  end

  if #distances == 0 then
    noZones[id] = true
    for _, ply in ipairs(player.GetAll()) do
      hook.Run("RPTools_ZoneEntered", id, ply)
    end
    return
  end

  local radius = math.max(unpack(distances))

  zones[id] = {
    getPosition = function()
      return RPTools.Node.GetPosition(node)
    end,
    radius = radius,
  }
end)

hook.Add("RPTools_NodeRemoved", "rptools_remove_zone", function(id)
  zones[id] = nil
end)

hook.Add("PlayerInitialSpawn", "rptools_zone_spawn", function(ply)
  for nodeId, _ in pairs(noZones) do
    hook.Run("RPTools_ZoneEntered", nodeId, ply)
  end
end)

local intersections = {}

local function calculateIntersections()
  for _, ply in ipairs(player.GetAll()) do
    local steamId = ply:SteamID64()
    local plyPosition = ply:GetPos()
    local previousIntersections = intersections[steamId] or {}
    local currentIntersections = {}

    for nodeId, zone in pairs(zones) do
      if plyPosition:DistToSqr(zone.getPosition()) <= zone.radius * zone.radius then
        currentIntersections[nodeId] = true
      end
    end

    for nodeId in pairs(currentIntersections) do
      if not previousIntersections[nodeId] then
        hook.Run("RPTools_ZoneEntered", nodeId, ply)
      end
    end

    for nodeId in pairs(previousIntersections) do
      if not currentIntersections[nodeId] then
        hook.Run("RPTools_ZoneExited", nodeId, ply)
      end
    end

    intersections[steamId] = currentIntersections
  end
end

hook.Add("PlayerDisconnected", "rptools_clean_intersections", function(ply)
  intersections[ply:SteamID64()] = nil
end)

hook.Add("RPTools_CoordinatorStarted", "rptools_start_intersection_calculation", function()
  timer.Create("rptools_zone", 0.2, 0, calculateIntersections)
end)

hook.Add("RPTools_CoordinatorStopped", "rptools_stop_intersection_calculation", function()
  timer.Remove("rptools_zone")
end)
