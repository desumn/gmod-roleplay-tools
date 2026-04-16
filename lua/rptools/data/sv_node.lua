RPTools = RPTools or {}
RPTools.Node = RPTools.Node or {}

local logModuleName = "Node"

local counter = 0

local function generateId()
  counter = counter + 1
  return "node_" .. counter
end

---@param node RPToolsNode
---@return string
function RPTools.Node.GenerateId(node)
  node.id = generateId()
  return node.id
end

local function validateId(id)
  return RPTools.Utilities.MakeError(isstring(id) and id ~= "", "Invalid id " .. tostring(id))
end

local function validatePosition(vector)
  return RPTools.Utilities.MakeError(
    isvector(vector)
      and RPTools.Utilities.IsNumber(vector.x)
      and RPTools.Utilities.IsNumber(vector.y)
      and RPTools.Utilities.IsNumber(vector.z),
    "Invalid vector: " .. tostring(vector)
  )
end

local fieldValidations = {
  id = validateId,
  position = validatePosition,
  conditions = RPTools.Condition.ValidateConditionSet,
  actions = RPTools.Actions.Server.ValidateActionsSet,
}

function RPTools.Node.ValidateNode(node)
  local finalResult = true
  local accumulatedError = ""

  for field, validate in pairs(fieldValidations) do
    if field == "id" and node.id == nil then
      continue
    end
    local result, str_error = validate(node[field])
    finalResult = finalResult and result
    if not result then
      accumulatedError = str_error .. ", " .. accumulatedError
    end
  end

  return finalResult, accumulatedError
end

---@param _position Vector
---@param _conditions RPToolsCondition[]
---@param _actions RPToolsAction[]
---@param _cooldownDuration? number
---@return RPToolsNode|nil, string|nil
function RPTools.Node.Create(_position, _conditions, _actions, _cooldownDuration)
  local node = {
    id = generateId(),
    position = _position or Vector(0, 0, 0),
    conditions = _conditions or RPTools.Condition.EmptyConditionSet(),
    actions = _actions or RPTools.Actions.Server.EmptyActionSet(),
    cooldownDuration = _cooldownDuration or 0,
  }

  local isValid, errorMessage = RPTools.Node.ValidateNode(node)

  if isValid then
    return node, nil
  else
    return nil, errorMessage
  end
end

---@param node RPToolsNode
---@return string
function RPTools.Node.GetId(node)
  return node.id
end

---@param node RPToolsNode
---@return Vector
function RPTools.Node.GetPosition(node)
  return node.position
end

---@param node RPToolsNode
---@return RPToolsCondition[]
function RPTools.Node.GetConditions(node)
  return node.conditions
end

---@param node RPToolsNode
---@return RPToolsAction[]
function RPTools.Node.GetActions(node)
  return node.actions
end

---@param node RPToolsNode
---@return integer
function RPTools.Node.GetCooldownDuration(node)
  return node.cooldownDuration
end

---@param node RPToolsNode
---@param subNode table
---@return string|nil
function RPTools.Node.Edit(node, subNode)
  local testNode = table.Copy(node)

  table.Merge(testNode, subNode)

  local isValid, errorMessage = RPTools.Node.ValidateNode(testNode)
  if not isValid then
    return errorMessage
  end

  table.Merge(node, subNode)
end
