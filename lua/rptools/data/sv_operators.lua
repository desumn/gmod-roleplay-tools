RPTools = RPTools or {}
RPTools.Operators = RPTools.Operators or {}

local operatorFunctions = {
  lt = function(l, r)
    return l < r
  end,
  gt = function(l, r)
    return l > r
  end,
  eq = function(l, r)
    return l == r
  end,
  ne = function(l, r)
    return l ~= r
  end,
  le = function(l, r)
    return l <= r
  end,
  ge = function(l, r)
    return l >= r
  end,

  between = function(value, bound)
    return value >= bound[1] and value <= bound[2]
  end,

  one_of = function(value, set)
    return set[value] == true
  end,
}

local formatters = {
  lt = function(l, r)
    return l .. " < " .. tostring(r)
  end,
  gt = function(l, r)
    return l .. " > " .. tostring(r)
  end,
  eq = function(l, r)
    return l .. " = " .. tostring(r)
  end,
  ne = function(l, r)
    return l .. " ≠ " .. tostring(r)
  end,
  le = function(l, r)
    return l .. " ≤ " .. tostring(r)
  end,
  ge = function(l, r)
    return l .. " ≥ " .. tostring(r)
  end,

  between = function(value, bound)
    return value .. " between " .. tostring(bound[1]) .. " and " .. tostring(bound[2])
  end,

  one_of = function(value, set)
    local formattedSet = "["
    for key, _ in pairs(set) do
      formattedSet = tostring(key) .. ", " .. formattedSet
    end
    formattedSet = formattedSet .. "]"
    return value .. " one of " .. formattedSet
  end,
}

---@param operator string
---@return function|nil, string|nil
function RPTools.Operators.GetFunction(operator)
  local operatorValid, operatorErrorMessage = RPTools.Operators.ValidateOperator(operator)

  if operatorValid then
    local opFunc = operatorFunctions[operator]
    local safeFunc = function(l, r)
      return l ~= nil and r ~= nil and opFunc(l, r)
    end
    return safeFunc, nil
  else
    return nil, operatorErrorMessage
  end
end

function RPTools.Operators.GetFormatter(operator)
  local operatorValid, operatorErrorMessage = RPTools.Operators.ValidateOperator(operator)

  if operatorValid then
    return formatters[operator], nil
  else
    return nil, operatorErrorMessage
  end
end

---@param operator string
---@return boolean, string
function RPTools.Operators.ValidateOperator(operator)
  return RPTools.Utilities.MakeError(
    operator and operatorFunctions[operator] ~= nil,
    "Unknown operator: " .. tostring(operator)
  )
end

---@param operator string
---@param value any
---@return boolean, string
function RPTools.Operators.ValidateValue(operator, value)
  if table.HasValue({ "le", "lt", "ge", "gt" }, operator) then
    return RPTools.Utilities.MakeError(
      RPTools.Utilities.IsNumber(value),
      "Value expected of type number: " .. tostring(value)
    )
  end

  if table.HasValue({ "eq", "ne" }, operator) then
    return RPTools.Utilities.MakeError(
      RPTools.Utilities.IsNumber(value) or isstring(value) or isbool(value),
      "Value expected of type number, boolean or string: " .. tostring(value)
    )
  end

  if table.HasValue({ "between" }, operator) then
    return RPTools.Utilities.MakeError(
      istable(value)
        and #value == 2
        and table.IsSequential(value)
        and RPTools.Utilities.IsNumber(value[1])
        and RPTools.Utilities.IsNumber(value[2]),
      "Value expected of type table with shape {lower, up}: " .. tostring(value)
    )
  end

  if table.HasValue({ "one_of" }, operator) then
    return RPTools.Utilities.MakeError(
      RPTools.Utilities.IsSet(value)
        and (RPTools.Utilities.AllKeys(value, isnumber) or RPTools.Utilities.AllKeys(value, isstring)),
      "Value expected a set : " .. tostring(value)
    )
  end

  return RPTools.Utilities.MakeError(false, "Unknown operator " .. tostring(operator))
end
