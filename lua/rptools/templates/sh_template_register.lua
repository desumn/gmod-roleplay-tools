RPTools = RPTools or {}
RPTools.Templating = RPTools.Templating or {}

local logModuleName = "Templating"
local templateRegister = {}

function RPTools.Templating.RegisterTemplate(template)
  local valid, errors = RPTools.Templating.ValidateTemplate(template)

  if valid then
    templateRegister[template.name] = template
    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Registered template " .. template.name)
  else
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Failed to register template " .. template.name .. ": " .. errors
    )
  end
end

function RPTools.Templating.GetAllTemplates()
  return table.Copy(templateRegister)
end

function RPTools.Templating.GetTemplateByName(name)
  return templateRegister[name]
end

if SERVER then
  ---@param template RPToolsTemplate
  ---@param arguments table
  ---@param context RPToolsContext
  ---@return RPToolsNode[]|nil, string|nil
  function RPTools.Templating.Execute(template, arguments, context)
    local validatedArguments, argumentsErrorMessage = RPTools.Templating.Apply(template, arguments)

    if not validatedArguments then
      return nil, argumentsErrorMessage
    end

    return template.transformer(validatedArguments, context)
  end

  RPTools.Network.OnClientMessage(RPTools.Network.MSG_TYPE.CREATE_FROM_TEMPLATE, function(ply)
    if not ply:IsAdmin() then
      return
    end

    local name = net.ReadString()
    local arguments = net.ReadTable()
    local pos = net.ReadVector()

    local context = { position = pos }

    local template = RPTools.Templating.GetTemplateByName(name)

    if template == nil then
      RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "No template: " .. name)
      return
    end

    local nodes, errorMessage = RPTools.Templating.Execute(template, arguments, context)

    if nodes == nil or table.IsEmpty(nodes) then
      RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Error executing the template:" .. errorMessage)
      return
    end

    for _, node in ipairs(nodes) do
      RPTools.NodeRegister.RegisterNode(node)
    end
  end)
end
