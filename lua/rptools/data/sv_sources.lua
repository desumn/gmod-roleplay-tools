RPTools = RPTools or {}

RPTools.Sources = RPTools.Sources or {}

local sourceFunctions = {
  distance = function(ply, node, _)
    return ply:GetPos():Distance(RPTools.Node.GetPosition(node))
  end,
  flag = function(ply, node, param)
    return RPTools.Blackboard.Read(ply, param)
  end,
}

---@param source string
---@return boolean, string
function RPTools.Sources.ValidateSource(source)
  return RPTools.Utilities.MakeError(sourceFunctions[source] ~= nil, "Invalid source: " .. tostring(source))
end

---@param source string
---@return fun(ply: Player, node: RPToolsNode, param: any): any
function RPTools.Sources.GetFunction(source)
  return sourceFunctions[source]
end

local validators = {
  distance = function(params)
    return params == nil
  end,
  flag = function(params)
    return isstring(params)
  end,
}

local expectedTypes = {
  distance = "none",
  flag = "key = string",
}

---@param source string
---@param param any
---@return boolean, string
function RPTools.Sources.ValidateParameter(source, param)
  return RPTools.Utilities.MakeError(
    validators[source](param),
    "Invalid params for source " .. tostring(source) .. "(" .. expectedTypes[source] .. ")" .. ": " .. tostring(param)
  )
end
