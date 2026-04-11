RPTools = RPTools or {}
RPTools.Templating = RPTools.Templating or {}

RPTools.Templating.ClientCache = {}

---@param templateName string
---@return RPToolsTemplate|nil
function RPTools.Templating.GetTemplateFromClientCache(templateName)
  return RPTools.Templating.ClientCache[templateName]
end

local function readParameter()
  local param = {}
  param.name = net.ReadString()
  param.description = net.ReadString()
  param.type = string.Trim(net.ReadString(), " ")

  local hasDisplay = net.ReadBool()

  if hasDisplay then
    param.display = net.ReadString()
  end

  param.required = net.ReadBool()

  local hasDefault = net.ReadBool()
  param.default = nil
  if hasDefault then
    if param.type == "bool" then
      param.default = net.ReadBool()
    elseif param.type == "number" then
      param.default = net.ReadUInt(16)
    elseif param.type == "string" then
      param.default = net.ReadString()
    end
  end
  return param
end

---@return RPToolsTemplate
function RPTools.Templating.ReadTemplateInfo()
  local template = {}
  template.name = net.ReadString()
  template.description = net.ReadString()

  local parameterCount = net.ReadUInt(4)
  template.parameters = {}

  for i = 1, parameterCount do
    local param = readParameter()
    table.insert(template.parameters, param)
  end

  return template
end

RPTools.Network.OnServerMessage(RPTools.Network.MSG_TYPE.TEMPLATE_SYNC, function()
  local templateCount = net.ReadUInt(8)
  RPTools.Templating.ClientCache = {}
  for i = 1, templateCount do
    local template = RPTools.Templating.ReadTemplateInfo()
    RPTools.Templating.ClientCache[template.name] = template
  end
  hook.Run("RPTools_TemplateSync", RPTools.Templating.ClientCache)
end)

concommand.Add("rptools_show_cache", function()
  PrintTable(RPTools.Templating.ClientCache)
end)
