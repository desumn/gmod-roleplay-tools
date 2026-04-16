RPTools = RPTools or {}
RPTools.Actions = RPTools.Actions or {}
RPTools.Actions.Server = RPTools.Actions.Server or {}

local logModuleName = "Action:Server"

local serverFunction = {}

local validators = {}

local formatters = {}

function RPTools.Actions.Server.RegisterAction(name, func, validator, formatter)
  serverFunction[name] = func
  validators[name] = validator
  formatters[name] = formatter
  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Registered action " .. name .. " on the server")
end

function RPTools.Actions.Server.RegisterClientAction(name, validator, formatter, target)
  validators[name] = validator
  formatters[name] = formatter

  local safeTarget = target or function(plys, _, _)
    return plys
  end
  serverFunction[name] = function(ply, node, params)
    RPTools.Network.SendToClients(safeTarget(ply, node, params), RPTools.Network.MSG_TYPE.CLIENT_ACTION, function()
      net.WriteString(name)
      net.WriteTable(params)
    end)
    return true
  end
  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Registered client-side action " .. name .. " on the server")
end

function RPTools.Actions.Server.GetFunction(name)
  return serverFunction[name]
end

function RPTools.Actions.Server.GetFormatter(name)
  return formatters[name]
end

---@param action RPToolsAction
---@return boolean, string|nil
function RPTools.Actions.Server.ValidateAction(action)
  local func = serverFunction[action.actionType]
  local validator = validators[action.actionType]

  local isValid = true
  local errorMessage = ""

  if not func or not isfunction(func) then
    isValid = false
    errorMessage = "Invalid function for action: " .. action.actionType .. " " .. errorMessage
  end

  if not validator or not isfunction(validator) then
    isValid = false
    errorMessage = "Invalid validator for action: " .. action.actionType .. " " .. errorMessage
  else
    local paramsValid, paramsError = validator(action.params)

    if not paramsValid then
      isValid = false
      errorMessage = (paramsError or "") .. action.actionType .. " " .. errorMessage
    end
  end
  return isValid, errorMessage
end

---@param actionType string
---@param params table
---@return RPToolsAction|nil, string|nil
function RPTools.Actions.Server.Create(actionType, params)
  local action = { actionType = actionType, params = params }
  local actionValid, errorMessage = RPTools.Actions.Server.ValidateAction(action)

  if actionValid then
    return action, nil
  else
    return nil, errorMessage
  end
end

---@return RPToolsAction[]
function RPTools.Actions.Server.EmptyActionSet()
  return {}
end

---@param set RPToolsAction[]
---@param action RPToolsAction
function RPTools.Actions.Server.AddToSet(set, action)
  table.insert(set, action)
end

---@param action RPToolsAction
---@return string
function RPTools.Actions.Server.GetActionType(action)
  return action.actionType
end

---@param action RPToolsAction
---@return table
function RPTools.Actions.Server.GetParams(action)
  return table.Copy(action.params)
end

---@param actions RPToolsAction[]
---@return boolean, string|nil
function RPTools.Actions.Server.ValidateActionsSet(actions)
  local allActionsValid = true
  local accumulatedErrorMessage = ""

  for _, action in ipairs(actions) do
    local actionValid, conditionErrorMessage = RPTools.Actions.Server.ValidateAction(action)
    allActionsValid = actionValid and allActionsValid
    if not actionValid then
      accumulatedErrorMessage = conditionErrorMessage .. ", " .. accumulatedErrorMessage
    end
  end

  if not allActionsValid then
    return false, accumulatedErrorMessage
  else
    return true, nil
  end
end
