RPTools = RPTools or {}
RPTools.Sources = RPTools.Sources or {}
RPTools.Sources.Server = RPTools.Sources.Server or {}

local logModuleName = "Sources:Server"

local sourceFunctions = {}
local validators = {}
local formatters = {}

function RPTools.Sources.Server.RegisterSource(name, func, validator, formatter)
  sourceFunctions[name] = func
  validators[name] = validator
  formatters[name] = formatter
  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Registered source " .. name .. " on the server")
end

---@param source string
---@return boolean, string
function RPTools.Sources.Server.ValidateSource(source)
  return RPTools.Utilities.MakeError(sourceFunctions[source] ~= nil, "Invalid source: " .. tostring(source))
end

---@param source string
---@return fun(ply: Player, node: RPToolsNode, param: any): any
function RPTools.Sources.Server.GetFunction(source)
  return sourceFunctions[source]
end

function RPTools.Sources.Server.GetFormatter(source)
  return formatters[source]
end

---@param source string
---@param param any
---@return boolean, string
function RPTools.Sources.Server.ValidateParameter(source, param)
  if not validators[source] or not isfunction(validators[source]) then
    return false, "Unknown source: " .. tostring(source)
  end
  return RPTools.Utilities.MakeError(
    validators[source](param),
    "Invalid params for source " .. tostring(source) .. ": " .. tostring(param)
  )
end
