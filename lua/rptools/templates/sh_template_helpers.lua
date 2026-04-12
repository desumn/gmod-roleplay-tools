RPTools = RPTools or {}
RPTools.Templating = RPTools.Templating or {}
RPTools.Templating.Parameters = RPTools.Templating.Parameters or {}

---@param name? string
---@param description? string
---@param default? number
---@return RPToolsParameter
function RPTools.Templating.Parameters.Distance(name, description, default)
  return {
    name = (name and name ~= "") or "distance",
    description = (description and description ~= "") or "activation distance",
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
---@return RPToolsParameter
function RPTools.Templating.Parameters.Flag(name, description)
  return {
    name = (name and name ~= "") or "required_flag",
    description = (description and description ~= "") or "activation distance",
    type = "string",
    display = "short",
    required = false,
    group = "trigger",
  }
end

---@param name? string
---@param description? string
---@param default? number
---@return RPToolsParameter
function RPTools.Templating.Parameters.Angle(name, description, default)
  return {
    name = (name and name ~= "") or "angle",
    description = (name and name ~= "") or "activation angle",
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
    name = (name and name ~= "") or "check_sight",
    description = (description and description ~= "") or "check if player can see the node",
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
    name = name or "Long string",
    description = description or "No desc",
    type = "string",
    display = "long",
    required = true,
    group = "action",
  }
end
