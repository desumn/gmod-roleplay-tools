RPTools = RPTools or {}
RPTools.Templating = RPTools.Templating or {}
RPTools.Templating.Parameters = RPTools.Templating.Parameters or {}

---@param name? string
---@param description? string
---@param default? number
---@return RPToolsParameter
function RPTools.Templating.Parameters.Distance(name, description, default)
  return {
    name = (name ~= nil and name ~= "" and name) or "distance",
    description = (description ~= nil and description ~= "" and description) or "activation distance",
    type = "number",
    required = true,
    default = default or 200,
    min = 0,
    max = 5000,
    group = "trigger",
  }
end

---@param name? string
---@param description? string
---@param required? boolean
---@param group? string
---@return RPToolsParameter
function RPTools.Templating.Parameters.Flag(name, description, required, group)
  return {
    name = (name ~= nil and name ~= "" and name) or "flag",
    description = (description ~= nil and description ~= "" and description) or "flag required for activation",
    type = "string",
    display = "short",
    required = required or false,
    group = group or "trigger",
  }
end

---@param name? string
---@param description? string
---@param default? number
---@return RPToolsParameter
function RPTools.Templating.Parameters.Angle(name, description, default)
  return {
    name = (name ~= nil and name ~= "" and name) or "angle",
    description = (description ~= nil and description ~= "" and description) or "activation angle",
    type = "number",
    required = false,
    default = default or 30,
    min = 1,
    max = 180,
    group = "trigger",
  }
end

---@param name? string
---@param description? string
---@return RPToolsParameter
function RPTools.Templating.Parameters.CheckSight(name, description)
  return {
    name = (name ~= nil and name ~= "" and name) or "check_sight",
    description = (description ~= nil and description ~= "" and description) or "check if player can see the node",
    type = "boolean",
    required = false,
    default = false,
    group = "trigger",
  }
end

---@param name? string
---@param description? string
---@return RPToolsParameter
function RPTools.Templating.Parameters.Boolean(name, description)
  return {
    name = (name ~= nil and name ~= "" and name) or "flag",
    description = (description ~= nil and description ~= "" and description) or "flag required for activation",
    type = "boolean",
    required = false,
    default = false,
    group = "trigger",
  }
end


---@param name? string
---@param description? string
function RPTools.Templating.Parameters.LongString(name, description)
  return {
    name = (name ~= nil and name ~= "" and name) or "Long string",
    description = (description ~= nil and description ~= "" and description) or "No desc",
    type = "string",
    display = "long",
    required = true,
    group = "action",
  }
end


---@param name? string
---@param description? string
---@param required? boolean
---@param group? string
---@param min? number
---@param max? number
---@return RPToolsParameter
function RPTools.Templating.Parameters.Number(name, description, min, max, required, default, group)
  return {
    name = (name ~= nil and name ~= "" and name) or "flag",
    description = (description ~= nil and description ~= "" and description) or "a number",
    type = "number",
    min = min or nil,
    max = max or nil,
    required = required or false,
    defualt = default or 0,
    group = group or "trigger",
  }
end

---@param name? string
---@param description? string
---@param required? boolean
---@param group? string
---@param min? number
---@param max? number
---@return RPToolsParameter
function RPTools.Templating.Parameters.Duration(name, description, required, group, min, max)
  return {
    name = (name ~= nil and name ~= "" and name) or "duration",
    description = (description ~= nil and description ~= "" and description) or "duration of the effect",
    type = "number",
    min = min or 1,
    max = max or 120,
    required = required or false,
    group = group or "action",
  }
end
