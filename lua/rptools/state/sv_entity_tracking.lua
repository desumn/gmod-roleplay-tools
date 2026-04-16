RPTools = RPTools or {}
RPTools.Entities = RPTools.Entities or {}

local counter = 0
local mapping = {}
local reverseMapping = {}

function RPTools.Entities.Register(entity)
  if not IsValid(entity) then
    return
  end

  if reverseMapping[entity] then
    return reverseMapping[entity]
  end

  local id = "ent_" .. tostring(counter)
  mapping[id] = entity
  reverseMapping[entity] = id

  counter = counter + 1
  return id
end

function RPTools.Entities.Get(id)
  return mapping[id]
end

local function removeFromTracking(entity)
  local id = reverseMapping[entity]
  if not id then
    return
  end

  mapping[id] = nil
  reverseMapping[entity] = nil

  hook.Run("RPTools_TrackedEntityRemoved", id, entity)
end

hook.Add("EntityRemoved", "rptools_entity_tracking_clean", function(entity, fullUpdate)
  if fullUpdate then
    return
  end
  removeFromTracking(entity)
end)

hook.Add("OnNPCKilled", "rptools_entity_tracking_clean_npc", function(npc)
  removeFromTracking(npc)
end)
