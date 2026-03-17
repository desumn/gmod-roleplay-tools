RPTools = RPTools or {}

local function requireAdmin(ply)
    if not ply:IsAdmin() then
        print("Permission denied")
        return
    else
        return true
    end
end

local function requireTemplate(args, pos)
    local templateName = args[pos]
    if not templateName then
        print("Please provide a template name, see rptools_template_list")
    end

    local template = RPTools.Templating.GetTemplateByName(templateName)
    if not template then
        print("Couldn't find template " .. templateName)
        return
    end

    return template
end

local function readParameter(arg)

    local explodedArg = string.Explode(":", arg)

    return explodedArg[1], explodedArg[2]

end


concommand.Add("rptools_template_list", function (ply, _, args, _)
    if not requireAdmin(ply) then return end
    local templateList = RPTools.Templating.GetAllTemplateNames()

    PrintTable(templateList)
end)

concommand.Add("rptools_template_info", function (ply, _, args, _)
    if not requireAdmin(ply) then return end
    local template = requireTemplate(args, 1)
    if not template then return end

    PrintTable(template)
end)

concommand.Add("rptools_template_execute", function (ply, _, args, _)
    requireAdmin(ply)

    local template = requireTemplate(args, 1)
    if not template then return end

    local parameters = RPTools.Templating.GetParameters(template)
    local arguments = {}

    for i, arg in ipairs(args) do
        if i == 0 or i == 1 then continue end
        local name, value = readParameter(arg)
        arguments[name] = value
    end


    local context = { position = ply:GetPos() + Vector(0, 0, 20) }
    local result_nodes, errorMessage = RPTools.Templating.Execute(template, arguments, context)

    if result_nodes == nil or result_nodes == {} then
        print("Error executing the template:" .. errorMessage)
        return
    end

    for _, node in ipairs(result_nodes) do
        RPTools.NodeRegister.RegisterNode(node)
    end
    
    
end)