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

local function validateRequiredTime(time)
  return RPTools.Utilities.MakeError(RPTools.Utilities.IsNumber(time), "Invalid required time: " .. tostring(time))
end

---@enum RPToolsTriggerPolicy
RPTools.Node.TRIGGER_POLICY = {
  MANUAL = 1,
  ONE_SHOT = 2,
  COOLDOWN = 3,
  CONTINOUS = 4,
}

local function validateTriggerPolicy(trigger_policy)
  return RPTools.Utilities.MakeError(
    RPTools.Utilities.IsNumber(trigger_policy) and trigger_policy >= 1 and trigger_policy <= 4,
    "Invalid trigger politic: " .. tostring(trigger_policy)
  )
end

---@enum RPToolsScope
RPTools.Node.SCOPE = {
  SINGLE_PLAYER = 1,
  GLOBAL = 2,
}

local function validateScope(scope)
  return RPTools.Utilities.MakeError(
    RPTools.Utilities.IsNumber(scope) and scope >= 1 and scope <= 2,
    "Invalid scope: " .. tostring(scope)
  )
end

local function validatePriority(priority)
  return RPTools.Utilities.MakeError(RPTools.Utilities.IsNumber(priority), "Invalid priority: " .. tostring(priority))
end

local fieldValidations = {
  id = validateId,
  position = validatePosition,
  conditions = RPTools.Condition.ValidateConditionSet,
  requiredTime = validateRequiredTime,
  actions = RPTools.Actions.ValidateActionsSet,
  triggerPolicy = validateTriggerPolicy,
  scope = validateScope,
  priority = validatePriority,
}

function RPTools.Node.ValidateNode(node)
  local finalResult = true
  local accumulatedError = ""

  for field, validate in pairs(fieldValidations) do
    if field == "id" and node.id == nil then continue end
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
---@param _required_time number
---@param _actions RPToolsAction[]
---@param _trigger_policy RPToolsTriggerPolicy
---@param _scope RPToolsScope
---@param _priority number
---@param _cooldownDuration? number
---@return RPToolsNode|nil, string|nil
function RPTools.Node.Create(
  _position,
  _conditions,
  _required_time,
  _actions,
  _trigger_policy,
  _scope,
  _priority,
  _cooldownDuration
)
  local node = {
    id = generateId(),
    position = _position or Vector(0, 0, 0),
    conditions = _conditions or RPTools.Condition.EmptyConditionSet(),
    requiredTime = _required_time or 0,
    actions = _actions or RPTools.Actions.EmptyActionSet(),
    triggerPolicy = _trigger_policy or RPTools.Node.TRIGGER_POLICY.ONE_SHOT,
    scope = _scope or RPTools.Node.SCOPE.SINGLE_PLAYER,
    priority = _priority or 0,
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
---@return integer
function RPTools.Node.GetRequiredTime(node)
  return node.requiredTime
end

---@param node RPToolsNode
---@return RPToolsAction[]
function RPTools.Node.GetActions(node)
  return node.actions
end

---@param node RPToolsNode
---@return RPToolsScope
function RPTools.Node.GetScope(node)
  return node.scope
end

---@param node RPToolsNode
---@return integer
function RPTools.Node.GetPriority(node)
  return node.priority
end

---@param node RPToolsNode
---@return RPToolsTriggerPolicy
function RPTools.Node.GetTriggerPolicy(node)
  return node.triggerPolicy
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
