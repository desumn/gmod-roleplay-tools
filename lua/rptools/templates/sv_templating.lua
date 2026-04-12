RPTools = RPTools or {}
RPTools.Templating = RPTools.Templating or {}

local logModuleName = "Templating"

local templateRegister = {}

---@param template RPToolsTemplate
function RPTools.Templating.RegisterTemplate(template)
  local isvalid, error_message = RPTools.Templating.ValidateTemplate(template)
  if not isvalid then
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Tried to register an invalid template (" .. error_message .. ")"
    )
    return
  end

  local name = template.name

  templateRegister[name] = template
  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Added template :" .. name .. " to the template register.")
end

---@param templateName string
function RPTools.Templating.UnregisterTemplate(templateName)
  if not templateRegister[templateName] then
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Tried to unregister a non-existant template (" .. tostring(templateName) .. ")"
    )
    return
  end

  templateRegister[templateName] = nil
  RPTools.Logs.log(
    RPTools.Logs.LEVEL.INFO,
    logModuleName,
    "Removed template :" .. templateName .. " from the template register."
  )
end

---@param templateName string
---@return RPToolsTemplate|nil
function RPTools.Templating.GetTemplateByName(templateName)
  if not templateRegister[templateName] then
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Tried to get a non-existant template (" .. tostring(templateName) .. ")"
    )
    return
  end

  return templateRegister[templateName]
end

---@return string[]
function RPTools.Templating.GetAllTemplateNames()
  local names = {}
  for name, _ in pairs(templateRegister) do
    table.insert(names, name)
  end
  return names
end

---@param template RPToolsTemplate
---@return boolean, string|nil
function RPTools.Templating.ValidateTemplate(template)
  local errorMessage = ""

  local isValid = true
  local name = template.name
  if not isstring(name) or name == "" then
    errorMessage = errorMessage .. ", name is not a string or is empty"
    isValid = false
  end

  local description = template.description
  if not isstring(description) or description == "" then
    errorMessage = errorMessage .. ", description is not a string or is empty"
    isValid = false
  end

  local parameters = template.parameters

  local parametersValid, parametersErrorMessage = RPTools.Templating.ValidateParameters(parameters)

  if not parametersValid then
    errorMessage = errorMessage .. ", " .. parametersErrorMessage
    isValid = false
  end

  if not isfunction(template.transformer) then
    errorMessage = errorMessage .. ", no transformation function provided"
    isValid = false
  end

  if not isValid then
    return false, errorMessage
  else
    return true, nil
  end
end

---@param template RPToolsTemplate
---@param arguments table
---@param context RPToolsContext
---@return RPToolsNode[]|nil, string|nil
function RPTools.Templating.Execute(template, arguments, context)
  local validatedArguments, argumentsErrorMessage = RPTools.Templating.ApplyParameters(template, arguments)

  if not validatedArguments then
    return nil, argumentsErrorMessage
  end

  return template.transformer(validatedArguments, context)
end

---@param template RPToolsTemplate
---@return string
function RPTools.Templating.GetName(template)
  return template.name
end

---@param template RPToolsTemplate
---@return RPToolsParameter[]
function RPTools.Templating.GetParameters(template)
  return table.Copy(template.parameters)
end

---@param template RPToolsTemplate
---@return fun(args: table, context: RPToolsContext): RPToolsNode[]|nil
function RPTools.Templating.GetTransformer(template)
  return template.transformer
end

---@param template RPToolsTemplate
---@return string
function RPTools.Templating.GetDescription(template)
  return template.description
end

local function writeParameter(parameter)
  net.WriteString(parameter.name)
  net.WriteString(parameter.description)
  net.WriteString(parameter.type)

  local hasDisplay = parameter.display ~= nil
  net.WriteBool(hasDisplay)
  if hasDisplay then
    net.WriteString(parameter.display)
  end

  net.WriteBool(parameter.required)

  local hasDefault = parameter.default ~= nil
  net.WriteBool(hasDefault)

  local type = parameter.type
  local default = parameter.default
  if hasDefault then
    if type == "bool" then
      net.WriteBool(default)
    elseif type == "number" then
      net.WriteUInt(default, 16)
    elseif type == "string" then
      net.WriteString(default)
    end
  end
end

---@param template RPToolsTemplate
function RPTools.Templating.WriteTemplateInfo(template)
  net.WriteString(template.name)
  net.WriteString(template.description)
  net.WriteUInt(#template.parameters, 4)
  for _, parameter in ipairs(template.parameters) do
    writeParameter(parameter)
  end
end

RPTools.Network.OnClientMessage(RPTools.Network.MSG_TYPE.CREATE_FROM_TEMPLATE, function(ply)
  if not ply:IsAdmin() then
    return
  end

  local name = net.ReadString()
  local arguments = net.ReadTable()
  local pos = net.ReadVector()

  local context = { position = pos }

  local nodes, errorMessage = RPTools.Templating.Execute(RPTools.Templating.GetTemplateByName(name), arguments, context)

  if nodes == nil or table.IsEmpty(nodes) then
    RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Error executing the template:" .. errorMessage)
    return
  end

  for _, node in ipairs(nodes) do
    RPTools.NodeRegister.RegisterNode(node)
  end
end)

concommand.Add("rptools_sync_templates", function(ply)
  if not ply:IsAdmin() then
    return
  end
  RPTools.Network.SendToPlayer(ply, RPTools.Network.MSG_TYPE.TEMPLATE_SYNC, function()
    local seqRegister = table.ClearKeys(templateRegister)
    net.WriteUInt(#seqRegister, 8)

    for _, template in ipairs(seqRegister) do
      RPTools.Templating.WriteTemplateInfo(template)
    end
  end)
end)
