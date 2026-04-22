RPTools = RPTools or {}

---@class RPToolsRange
---@field min? number
---@field max? number
---@field exclusive? { min? : boolean, max? : boolean }

---@param value number
---@param range RPToolsRange
---@return boolean
local function checkRange(value, range)
  local exclusive = {
    min = range.exclusive and range.exclusive.min or false,
    max = range.exclusive and range.exclusive.max or false,
  }

  local minCondition = true
  local maxCondition = true

  if range.min then
    minCondition = range.min <= value
    if exclusive.min then
      minCondition = minCondition and range.min ~= value
    end
  end

  if range.max then
    maxCondition = value <= range.max
    if exclusive.max then
      maxCondition = maxCondition and range.max ~= value
    end
  end

  return minCondition and maxCondition
end

---@alias RPToolsEquatableValues boolean | number | string

---@class RPToolsEquality<T>
---@field equals? T : RPToolsEquatableValues
---@field notEquals? T

---@generic T : RPToolsEquatableValues
---@param value T
---@param equality RPToolsEquality<T>
---@return boolean
local function checkEquality(value, equality)
  local equalsCondition = true
  local notEqualsCondition = true

  if equality.equals ~= nil then
    equalsCondition = value == equality.equals
  end

  if equality.notEquals ~= nil then
    notEqualsCondition = value ~= equality.notEquals
  end

  return equalsCondition and notEqualsCondition
end

local Data = {}

---@param ply Player
---@param node RPToolsNodeEntity
---@return number
function Data.getDistance(ply, node)
  return ply:GetPos():Distance(node:GetPos())
end

---@param ply Player
---@param node RPToolsNodeEntity
---@return number
function Data.getViewAngle(ply, node)
  local direction = (node:GetPos() - ply:GetShootPos()):GetNormalized()
  return ply:GetAimVector():Dot(direction)
end

---@param ply Player
---@param node RPToolsNodeEntity
---@return boolean
function Data.getLineOfSight(ply, node)
  local tr = util.TraceLine({
    start = ply:GetShootPos(),
    endpos = node:GetPos(),
    filter = ply,
  })
  return not tr.Hit
end

---@class RPToolsDistanceCondition : RPToolsRange
---@field type "spatial"
---@field test "distance"

---@class RPToolsViewAngleCondition : RPToolsRange
---@field type "spatial"
---@field test "view_angle"

---@class RPToolsLineOfSightCondition : RPToolsEquality<boolean>
---@field type "spatial"
---@field test "line_of_sight"

---@alias RPToolsSpatialCondition RPToolsDistanceCondition | RPToolsViewAngleCondition | RPToolsLineOfSightCondition

---@param condition RPToolsSpatialCondition
---@param ply Player
---@param node RPToolsNodeEntity
---@return boolean
local function evaluateSpatial(condition, ply, node)
  if condition.test == "distance" then
    return checkRange(Data.getDistance(ply, node), condition)
  elseif condition.test == "view_angle" then
    return checkRange(Data.getViewAngle(ply, node), condition)
  elseif condition.test == "line_of_sight" then
    return checkEquality(Data.getLineOfSight(ply, node), condition)
  else
    error("Unmatched condition type " .. condition.test)
  end
end

---@class RPToolsFlagCondition : RPToolsEquality<boolean>
---@field type "state"
---@field key string
---@field scope RPToolsStateScope
---@field valueType "boolean"

---@class RPToolsNumberCondition : RPToolsRange
---@field type "state"
---@field key string
---@field scope RPToolsStateScope
---@field valueType "number"

---@class RPToolsStringCondition : RPToolsEquality<string>
---@field type "state"
---@field key string
---@field scope RPToolsStateScope
---@field valueType "string"

---@alias RPToolsStateCondition RPToolsFlagCondition|RPToolsNumberCondition|RPToolsStringCondition

---@param condition RPToolsStateCondition
---@param ply? Player
---@return boolean
local function evaluateState(condition, ply)
  if condition.valueType == "boolean" then
    local value = RPTools.State.Server.GetBoolean(condition.scope, condition.key, ply)
    return value ~= nil and checkEquality(value, condition)
  elseif condition.valueType == "number" then
    local value = RPTools.State.Server.GetNumber(condition.scope, condition.key, ply)
    return value ~= nil and checkRange(value, condition)
  elseif condition.valueType == "string" then
    local value = RPTools.State.Server.GetString(condition.scope, condition.key, ply)
    return value ~= nil and checkEquality(value, condition)
  else
    error("Invalid type for state condition " .. condition.valueType)
  end
end

---@alias RPToolsCondition RPToolsSpatialCondition | RPToolsStateCondition

---@param conditions RPToolsCondition[]
---@param ply Player
---@param node RPToolsNodeEntity
---@return boolean
local function evaluate(conditions, ply, node)
  for _, condition in ipairs(conditions) do
    if condition.type == "spatial" then
      ---@cast condition RPToolsSpatialCondition
      if not evaluateSpatial(condition, ply, node) then
        return false
      end
    elseif condition.type == "state" then
      ---@cast condition RPToolsStateCondition
      if not evaluateState(condition, ply) then
        return false
      end
    end
  end

  return true
end

RPTools.Conditions = {
  Evaluate = evaluate,
}
