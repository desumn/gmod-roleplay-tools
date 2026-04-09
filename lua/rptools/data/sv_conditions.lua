RPTools = RPTools or {}
RPTools.Condition = RPTools.Condition or {}

---@param condition RPToolsCondition
---@return boolean, string
function RPTools.Condition.ValidateCondition(condition)
  local finalResult = true
  local accumulatedErrorMessage = ""

  local sourceValid, sourceErrorMessage = RPTools.Sources.ValidateSource(condition.source)
  finalResult = finalResult and sourceValid
  if not sourceValid then
    accumulatedErrorMessage = sourceErrorMessage .. ", " .. accumulatedErrorMessage
  end

  local operatorValid, operatorErrorMessage = RPTools.Operators.ValidateOperator(condition.operator)
  finalResult = finalResult and operatorValid
  if not operatorValid then
    accumulatedErrorMessage = operatorErrorMessage .. ", " .. accumulatedErrorMessage
  end

  if operatorValid then
    local valueValid, valueErrorMessage = RPTools.Operators.ValidateValue(condition.operator, condition.value)
    finalResult = finalResult and valueValid
    if not valueValid then
      accumulatedErrorMessage = valueErrorMessage .. ", " .. accumulatedErrorMessage
    end
  end

  if sourceValid then
    local paramValid, paramErrorMessage = RPTools.Sources.ValidateParameter(condition.source, condition.sourceParameter)
    finalResult = finalResult and paramValid
    if not paramValid then
      accumulatedErrorMessage = paramErrorMessage .. ", " .. accumulatedErrorMessage
    end
  end

  return finalResult, accumulatedErrorMessage
end

---@param conditions RPToolsCondition[]
---@return boolean, string
function RPTools.Condition.ValidateConditionSet(conditions)
  local allConditionsValid = true
  local accumulatedErrorMessage = ""

  for _, condition in ipairs(conditions) do
    local conditionValid, conditionErrorMessage = RPTools.Condition.ValidateCondition(condition)
    allConditionsValid = conditionValid and allConditionsValid
    if not conditionValid then
      accumulatedErrorMessage = conditionErrorMessage .. ", " .. accumulatedErrorMessage
    end
  end

  if not allConditionsValid then
    return false, accumulatedErrorMessage
  else
    return true, nil
  end
end

---@param source string
---@param sourceParameter any
---@param operator string
---@param value any
---@return RPToolsCondition|nil, string|nil
function RPTools.Condition.Create(source, sourceParameter, operator, value)
  local condition = {
    source = source,
    sourceParameter = sourceParameter,
    operator = operator,
    value = value,
  }

  local conditionValid, conditionErrorMessage = RPTools.Condition.ValidateCondition(condition)

  if not conditionValid then
    return nil, conditionErrorMessage
  else
    return condition, nil
  end
end

---@param condition RPToolsCondition
---@return string
function RPTools.Condition.GetSource(condition)
  return condition.source
end

---@param condition RPToolsCondition
---@return any
function RPTools.Condition.GetSourceParameter(condition)
  return condition.sourceParameter
end

---@param condition RPToolsCondition
---@return string
function RPTools.Condition.GetOperator(condition)
  return condition.operator
end

---@param condition RPToolsCondition
---@return any
function RPTools.Condition.GetValue(condition)
  return condition.value
end

---@return RPToolsCondition[]
function RPTools.Condition.EmptyConditionSet()
  return {}
end

---@param set RPToolsCondition[]
---@param condition RPToolsCondition
function RPTools.Condition.AddToSet(set, condition)
  table.insert(set, condition)
end

---@param conditions RPToolsCondition[]
---@return RPToolsCondition[]|nil, string|nil
function RPTools.Condition.CreateConditionSet(conditions)
  local conditionSetValid, conditionErrorMessage = RPTools.Condition.ValidateConditionSet(conditions)

  if not conditionSetValid then
    return nil, conditionErrorMessage
  else
    return conditions, nil
  end
end
