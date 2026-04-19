RPTools = RPTools or {}

---@param oldNode RPToolsNodeEntity
---@return RPToolsNodeEntity
local function copyNode(oldNode)
  local node = ents.Create("ent_rptools_node")
  ---@cast node RPToolsNodeEntity

  node.conditions = table.Copy(oldNode.conditions)
  node.actions = table.Copy(oldNode.actions)

  node.state = table.Copy(oldNode.state)

  node.debug = table.Copy(oldNode.debug)

  node:SetPos(oldNode:GetPos())
  if IsValid(oldNode:GetParent()) then
    node:SetParent(oldNode:GetParent())
  end

  return node
end

---@param node RPToolsNodeEntity
---@param index integer
---@return RPToolsNodeEntity?
local function removeCondition(node, index)
  if index < 1 or index > #node.conditions then
    return nil
  end

  local newNode = copyNode(node)
  table.remove(newNode.conditions, index)

  newNode:Spawn()
  node:Remove()

  return newNode
end

---@param node RPToolsNodeEntity
---@param indexes integer[]
---@return RPToolsNodeEntity?
local function removeConditions(node, indexes)
  local newNode = copyNode(node)
  for offset, index in ipairs(indexes) do
    if index < 1 or index > #node.conditions then
      return nil
    end

    table.remove(newNode.conditions, index - (offset - 1))
  end

  newNode:Spawn()
  node:Remove()

  return newNode
end

---@param node RPToolsNodeEntity
---@param index integer
---@return RPToolsNodeEntity?
local function removeAction(node, index)
  if index < 1 or index > #node.actions then
    return nil
  end

  table.remove(node.actions, index)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@param node RPToolsNodeEntity
---@param min? number
---@param max? number
---@return RPToolsNodeEntity?
local function addDistance(node, min, max)
  if min ~= nil and min < 0 then
    return nil
  end
  if min ~= nil and max ~= nil and max < min then
    return nil
  end

  ---@type RPToolsSpatialCondition
  local distanceCondition = { type = "spatial", test = "distance", min = min, max = max }

  local newNode = copyNode(node)

  table.insert(newNode.conditions, distanceCondition)

  newNode:Spawn()
  node:Remove()

  return newNode
end

---@param node RPToolsNodeEntity
---@param maxAngleDegrees number
---@return RPToolsNodeEntity?
local function addViewAngle(node, maxAngleDegrees)
  if maxAngleDegrees < 0 or maxAngleDegrees > 180 then
    return nil
  end
  local minDotProduct = math.cos(math.rad(maxAngleDegrees))

  ---@type RPToolsSpatialCondition
  local angleCondition = { type = "spatial", test = "view_angle", min = minDotProduct }

  local hasDistance = false
  for _, condition in ipairs(node.conditions) do
    if condition.test == "distance" then
      hasDistance = true
    end
  end

  if not hasDistance then
    return nil
  end

  for _, condition in ipairs(node.conditions) do
    if condition.test == "view_angle" then
      return nil
    end
  end

  table.insert(node.conditions, angleCondition)

  hook.Run("RPTools_NodeEdited", node)
  return node
end

---@param node RPToolsNodeEntity
---@param shouldLineOfSight boolean
---@return RPToolsNodeEntity?
local function addLineOfSight(node, shouldLineOfSight)
  ---@type RPToolsSpatialCondition
  local losCondition = { type = "spatial", test = "line_of_sight", equals = shouldLineOfSight }

  local hasDistance = false
  for _, condition in ipairs(node.conditions) do
    if condition.test == "distance" then
      hasDistance = true
    end
  end

  if not hasDistance then
    return nil
  end

  for _, condition in ipairs(node.conditions) do
    if condition.test == "line_of_sight" then
      return nil
    end
  end

  table.insert(node.conditions, losCondition)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@param node RPToolsNodeEntity
---@param scope RPToolsStateScope
---@param key string
---@param equals? any
---@param notEquals? any
---@return RPToolsNodeEntity?
local function addStateCondition(node, scope, key, equals, notEquals)
  if not (scope == RPTools.State.SCOPE.GLOBAL or scope == RPTools.State.SCOPE.PLAYER) then
    return nil
  end
  if equals == nil and notEquals == nil then
    return
  end
  if equals ~= nil and notEquals ~= nil then
    return nil
  end

  ---@type RPToolsStateCondition
  local stateCondition = { type = "state", scope = scope, key = key, equals = equals, notEquals = notEquals }

  local newNode = copyNode(node)

  for _, condition in ipairs(node.conditions) do
    if condition.scope == scope and condition.key == key then
      return nil
    end
  end

  table.insert(newNode.conditions, stateCondition)

  newNode:Spawn()
  node:Remove()

  return newNode
end

---@param node RPToolsNodeEntity
---@param message string
---@return RPToolsNodeEntity
local function addMessage(node, message)
  ---@type RPToolsPlayerAction
  local messageAction = { target = "player", action = "send_message", message = message }

  table.insert(node.actions, messageAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@param node RPToolsNodeEntity
---@param message string
---@param duration number
---@return RPToolsNodeEntity
local function addHUDMessage(node, message, duration)
  ---@type RPToolsPlayerAction
  local HUDMessageAction = { target = "player", action = "hud_message", message = message, duration = duration }

  table.insert(node.actions, HUDMessageAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@param node RPToolsNodeEntity
---@param sound string
---@param pitch? number
---@param volume? number
---@return RPToolsNodeEntity?
local function addPlayPlayerSound(node, sound, volume, pitch)
  if volume ~= nil and (volume < 0 or volume > 1) then
    return nil
  end
  if pitch ~= nil and (pitch < 0 or pitch > 255) then
    return nil
  end
  if not file.Exists("sound/" .. sound, "GAME") then
    return nil
  end

  ---@type RPToolsPlayerAction
  local playSoundAction = { target = "player", action = "play_sound", sound = sound, volume = volume, pitch = pitch }

  table.insert(node.actions, playSoundAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@param node RPToolsNodeEntity
---@param sound string
---@param pitch? number
---@param volume? number
---@param level? number
---@return RPToolsNodeEntity?
local function addPlayWorldSound(node, sound, volume, pitch, level)
  if volume ~= nil and (volume < 0 or volume > 1) then
    return nil
  end
  if pitch ~= nil and (pitch < 0 or pitch > 255) then
    return nil
  end
  if level ~= nil and level and (level < 0 or level > 511) then
    return nil
  end
  if not file.Exists("sound/" .. sound, "GAME") then
    return nil
  end

  ---@type RPToolsWorldAction
  local playSoundAction =
    { target = "world", action = "play_sound", sound = sound, volume = volume, pitch = pitch, level = level }

  table.insert(node.actions, playSoundAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@param node RPToolsNodeEntity
---@param sound string
---@param iterations? number
---@param pitch? number
---@param volume? number
---@param level? number
---@return RPToolsNodeEntity?
local function addLoopSound(node, sound, iterations, volume, pitch, level)
  if volume ~= nil and (volume < 0 or volume > 1) then
    return nil
  end
  if pitch ~= nil and (pitch < 0 or pitch > 255) then
    return nil
  end
  if level ~= nil and level and (level < 0 or level > 511) then
    return nil
  end
  if not file.Exists("sound/" .. sound, "GAME") then
    return nil
  end
  if iterations ~= nil and iterations < 0 then
    return nil
  end

  ---@type RPToolsWorldAction
  local playSoundAction = {
    target = "world",
    action = "loop_sound",
    iterations = iterations,
    sound = sound,
    volume = volume,
    pitch = pitch,
    level = level,
  }

  table.insert(node.actions, playSoundAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@param node RPToolsNodeEntity
---@param message string
---@return RPToolsNodeEntity
local function addBroadcastMessage(node, message)
  ---@type RPToolsBroadcastAction
  local messageAction = { target = "broadcast", action = "send_message", message = message }

  table.insert(node.actions, messageAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@param node RPToolsNodeEntity
---@param scope RPToolsStateScope
---@param key string
---@param value any
---@pram duration number
---@return RPToolsNodeEntity?
local function addStateSet(node, scope, key, value, duration)
  if not (scope == RPTools.State.SCOPE.GLOBAL or scope == RPTools.State.SCOPE.PLAYER) then
    return nil
  end

  ---@type RPToolsStateAction
  local stateAction = { target = "state", action = "set", scope = scope, key = key, value = value, duration = duration }

  table.insert(node.actions, stateAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@param node RPToolsNodeEntity
---@param scope RPToolsStateScope
---@param key string
---@return RPToolsNodeEntity?
local function addStateRemove(node, scope, key)
  if not (scope == RPTools.State.SCOPE.GLOBAL or scope == RPTools.State.SCOPE.PLAYER) then
    return nil
  end

  ---@type RPToolsStateAction
  local stateAction = { target = "state", action = "remove", scope = scope, key = key }

  table.insert(node.actions, stateAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

RPTools.Transformers = {
  AddDistance = addDistance,
  AddViewAngle = addViewAngle,
  AddLineOfSight = addLineOfSight,
  AddStateCondition = addStateCondition,
  AddMessage = addMessage,
  AddHUDMessage = addHUDMessage,
  AddPlayPlayerSound = addPlayPlayerSound,
  AddPlayWorldSound = addPlayWorldSound,
  AddLoopSound = addLoopSound,
  AddBroadCastMessage = addBroadcastMessage,
  AddStateSet = addStateSet,
  AddStateRemove = addStateRemove,
  RemoveCondition = removeCondition,
  RemoveConditions = removeConditions,
  RemoveAction = removeAction,
}
