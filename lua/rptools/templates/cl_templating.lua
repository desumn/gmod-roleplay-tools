RPTools = RPTools or {}
RPTools.Templating = RPTools.Templating or {}

RPTools.Templating.ClientCache = {}

local function readParameter()
        local param = {}
        param.name = net.ReadString()
        param.description = net.ReadString()
        param.type = net.ReadString()
        param.required = net.ReadBool()

        local hasDefault = net.ReadBool()
        param.default = nil
        if hasDefault then
            if type == "bool" then
                param.default = net.ReadBool()
            elseif type == "number" then
                param.default = net.ReadUInt(16)
            elseif type == "string" then
                param.default = net.ReadString
            end
        end
        return param
end


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

RPTools.Network.RegisterServerHandler(RPTools.Network.MSG_TYPE.TEMPLATE_SYNC, function ()
    local templateCount = net.ReadUInt(8)
    RPTools.Templating.ClientCache = {}
    for i=1, templateCount do
        RPTools.Templating.ClientCache[i] = RPTools.Templating.ReadTemplateInfo()
    end
end)

concommand.Add("rptools_show_cache", function()
    PrintTable(RPTools.Templating.ClientCache)
end)