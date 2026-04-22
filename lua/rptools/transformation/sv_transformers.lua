RPTools = RPTools or {}

---@nodiscard
---@param node RPToolsNodeEntity
---@param index integer
---@return RPToolsNodeEntity?
local function removeCondition(node, index)
  if index < 1 or index > #node.conditions then
    return nil
  end

  table.remove(node.conditions, index)

  node:ReInitialize()
  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@param indexes integer[]
---@return RPToolsNodeEntity?
local function removeConditions(node, indexes)
  for offset, index in ipairs(indexes) do
    if index < 1 or index > #node.conditions then
      return nil
    end

    table.remove(node.conditions, index - (offset - 1))
  end

  node:ReInitialize()
  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
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

---@nodiscard
---@param node RPToolsNodeEntity
---@param parent Entity
---@return RPToolsNodeEntity?
local function setParent(node, parent)
  if not IsValid(parent) then
    return
  end

  node:SetParent(parent)
  node:SetLocalPos(Vector(0, 0, 0))

  if node.isSpatial then
    node:ReInitialize()
  end

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@return RPToolsNodeEntity?
local function removeParent(node)
  node:SetParent(nil)

  if node.isSpatial then
    node:ReInitialize()
  end

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@param node RPToolsNodeEntity
---@param condition RPToolsCondition
local function insertOrUpdateCondition(node, condition)
  local updated = false
  for i, oldCondition in ipairs(node.conditions) do
    if oldCondition.type == condition.type and condition.type == "spatial" and condition.test == oldCondition.test then
      node.conditions[i] = condition
      updated = true
      break
    elseif
      oldCondition.type == condition.type
      and condition.type == "state"
      and oldCondition.scope == condition.scope
      and oldCondition.key == condition.key
    then
      node.conditions[i] = condition
      updated = true
      break
    end
  end

  if not updated then
    table.insert(node.conditions, condition)
  end
end

---@param node RPToolsNodeEntity
---@param action RPToolsAction
local function insertOrUpdateAction(node, action)
  local updated = false
  for i, oldAction in ipairs(node.actions) do
    if
      oldAction.target == action.target
      and action.target == "state"
      and oldAction.scope == action.scope
      and oldAction.key == action.key
    then
      node.actions[i] = action
      updated = true
      break
    end
  end

  if not updated then
    table.insert(node.actions, action)
  end
end

---@nodiscard
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

  ---@type RPToolsDistanceCondition
  local distanceCondition = { type = "spatial", test = "distance", min = min, max = max }

  insertOrUpdateCondition(node, distanceCondition)
  node:ReInitialize()

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@param maxAngleDegrees number
---@return RPToolsNodeEntity?
local function addViewAngle(node, maxAngleDegrees)
  if maxAngleDegrees < 0 or maxAngleDegrees > 180 then
    return nil
  end

  local hasDistance = false
  for _, condition in ipairs(node.conditions) do
    if condition.test == "distance" then
      hasDistance = true
      break
    end
  end

  if not hasDistance then
    return nil
  end

  local minDotProduct = math.cos(math.rad(maxAngleDegrees))

  ---@type RPToolsViewAngleCondition
  local angleCondition = { type = "spatial", test = "view_angle", min = minDotProduct }

  insertOrUpdateCondition(node, angleCondition)
  node:ReInitialize()

  hook.Run("RPTools_NodeEdited", node)
  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@param shouldLineOfSight boolean
---@return RPToolsNodeEntity?
local function addLineOfSight(node, shouldLineOfSight)
  local hasDistance = false
  for _, condition in ipairs(node.conditions) do
    if condition.test == "distance" then
      hasDistance = true
      break
    end
  end

  if not hasDistance then
    return nil
  end

  ---@type RPToolsLineOfSightCondition
  local losCondition = { type = "spatial", test = "line_of_sight", equals = shouldLineOfSight }

  insertOrUpdateCondition(node, losCondition)
  node:ReInitialize()

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@param scope RPToolsStateScope
---@param key string
---@return RPToolsNodeEntity?
local function addFlagCondition(node, scope, key, invert)
  if not (scope == RPTools.State.Shared.SCOPE.GLOBAL or scope == RPTools.State.Shared.SCOPE.PLAYER) then
    return nil
  end

  local equality = invert and "notEquals" or "equals"

  ---@type RPToolsFlagCondition
  local stateCondition = { type = "state", scope = scope, key = key, [equality] = true, valueType = "boolean" }

  insertOrUpdateCondition(node, stateCondition)
  node:ReInitialize()

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@param scope RPToolsStateScope
---@param key string
---@param min? number
---@param max? number
---@param exclusive? { min : boolean, max : boolean}
---@return RPToolsNodeEntity?
local function addNumberCondition(node, scope, key, min, max, exclusive)
  if not (scope == RPTools.State.Shared.SCOPE.GLOBAL or scope == RPTools.State.Shared.SCOPE.PLAYER) then
    return nil
  end
  if min == nil and max == nil then
    return nil
  end

  ---@type RPToolsNumberCondition
  local stateCondition =
    { type = "state", scope = scope, key = key, min = min, max = max, exclusive = exclusive, valueType = "number" }

  insertOrUpdateCondition(node, stateCondition)
  node:ReInitialize()

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@param scope RPToolsStateScope
---@param key string
---@param value? string
---@param invert? boolean
---@return RPToolsNodeEntity?
local function addStringCondition(node, scope, key, value, invert)
  if not (scope == RPTools.State.Shared.SCOPE.GLOBAL or scope == RPTools.State.Shared.SCOPE.PLAYER) then
    return nil
  end
  if value == nil or value == "" then
    return nil
  end

  local equality = invert and "notEquals" or "equals"

  ---@type RPToolsStringCondition
  local stateCondition = { type = "state", scope = scope, key = key, [equality] = value, valueType = "string" }

  insertOrUpdateCondition(node, stateCondition)
  node:ReInitialize()

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@param message string
---@return RPToolsNodeEntity
local function addMessage(node, message)
  ---@type RPToolsMessageAction
  local messageAction = { target = "player", action = "send_message", message = message }

  insertOrUpdateAction(node, messageAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@param message string
---@param duration number
---@return RPToolsNodeEntity
local function addHUDMessage(node, message, duration)
  ---@type RPToolsHUDMessageAction
  local HUDMessageAction = { target = "player", action = "hud_message", message = message, duration = duration }

  insertOrUpdateAction(node, HUDMessageAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
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

  ---@type RPToolsPlaySoundAction
  local playSoundAction = { target = "player", action = "play_sound", sound = sound, volume = volume, pitch = pitch }

  insertOrUpdateAction(node, playSoundAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
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

  ---@type RPToolsPlaySoundWorldAction
  local playSoundAction =
    { target = "world", action = "play_sound", sound = sound, volume = volume, pitch = pitch, level = level }

  insertOrUpdateAction(node, playSoundAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
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

  if iterations ~= nil and iterations < 0 then
    return nil
  end

  ---@type RPToolsLoopSoundAction
  local playSoundAction = {
    target = "world",
    action = "loop_sound",
    iterations = iterations,
    sound = sound,
    volume = volume,
    pitch = pitch,
    level = level,
  }

  insertOrUpdateAction(node, playSoundAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@param message string
---@return RPToolsNodeEntity
local function addBroadcastMessage(node, message)
  ---@type RPToolsBroadcastMessageAction
  local messageAction = { target = "broadcast", action = "send_message", message = message }

  insertOrUpdateAction(node, messageAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@param scope RPToolsStateScope
---@param key string
---@param value any
---@param duration number
---@return RPToolsNodeEntity?
local function addStateSet(node, scope, key, value, duration)
  if not (scope == RPTools.State.Shared.SCOPE.GLOBAL or scope == RPTools.State.Shared.SCOPE.PLAYER) then
    return nil
  end

  local valueType
  local typeID = TypeID(value)
  if typeID == TYPE_BOOL then
    valueType = "boolean"
  elseif typeID == TYPE_NUMBER then
    valueType = "number"
  elseif typeID == TYPE_STRING then
    valueType = "string"
  else
    return nil
  end

  ---@type RPToolsStateSetAction
  local stateAction = {
    target = "state",
    action = "set",
    scope = scope,
    key = key,
    value = value,
    valueType = valueType,
    duration = duration,
  }

  insertOrUpdateAction(node, stateAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

---@nodiscard
---@param node RPToolsNodeEntity
---@param scope RPToolsStateScope
---@param key string
---@return RPToolsNodeEntity?
local function addStateRemove(node, scope, key)
  if not (scope == RPTools.State.Shared.SCOPE.GLOBAL or scope == RPTools.State.Shared.SCOPE.PLAYER) then
    return nil
  end

  ---@type RPToolsStateRemoveAction
  local stateAction = { target = "state", action = "remove", scope = scope, key = key }

  insertOrUpdateAction(node, stateAction)

  hook.Run("RPTools_NodeEdited", node)

  return node
end

RPTools.Transformers = {
  SetParent = setParent,
  RemoveParent = removeParent,
  AddDistance = addDistance,
  AddViewAngle = addViewAngle,
  AddLineOfSight = addLineOfSight,
  AddFlagCondition = addFlagCondition,
  AddNumberCondition = addNumberCondition,
  AddStringCondition = addStringCondition,
  AddMessage = addMessage,
  AddHUDMessage = addHUDMessage,
  AddPlayPlayerSound = addPlayPlayerSound,
  AddPlayWorldSound = addPlayWorldSound,
  AddLoopSound = addLoopSound,
  AddBroadcastMessage = addBroadcastMessage,
  AddStateSet = addStateSet,
  AddStateRemove = addStateRemove,
  RemoveCondition = removeCondition,
  RemoveConditions = removeConditions,
  RemoveAction = removeAction,
}
