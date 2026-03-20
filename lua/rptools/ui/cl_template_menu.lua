

local function makeFrame(name)
    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW() * 0.18, ScrH() * 0.7)
    frame:CenterVertical()
    frame:AlignRight(ScrW() * 0.005)
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:SetTitle("Create Node From Template -- " .. name)
    frame:MakePopup()
    return frame
end

local function makeTitle(name, frame)
    local title = vgui.Create("DLabel", frame)
    title:SetFont("DermaLarge")
    title:SetText(name)
    title:SetTextColor(color_white)
    title:SizeToContents()
    title:SetContentAlignment(5)
    title:SetTall(30)
    title:DockMargin(10, 10, 10, 5)
    title:Dock(TOP)
    return title
end

local function makeDescription(description, frame)
    local descLabel = vgui.Create("DLabel", frame)
    descLabel:SetFont("DermaDefault")
    descLabel:SetText(description)
    descLabel:SetTextColor(Color(180, 180, 180))
    
    descLabel:SetWrap(true)
    descLabel:SetAutoStretchVertical(true)
    
    descLabel:SizeToContents()
    descLabel:SetContentAlignment(5)
    descLabel:DockMargin(10, 0, 10, 10)
    descLabel:Dock(TOP)
    return descLabel
end

local function makeSeparator(frame)
    local separator = vgui.Create("DPanel", frame)
    
    separator:SetTall(2)
    
    separator.Paint = function(self, w, h)
        surface.SetDrawColor(Color(100, 100, 100))
        surface.DrawRect(0, 0, w, h)
    end
    
    
    separator:DockMargin(10, 5, 10, 5)
    separator:Dock(TOP)
    
    return separator
end

local function makeSubmitButton(frame)
    local button = vgui.Create("DButton", frame)
    
    button:SetTall(35)
    
    button:SetText("Create Node")
    
    
    button:SetEnabled(false)
    button:DockMargin(10, 5, 10, 10)
    button:Dock(BOTTOM)
    return button
end


local displayWidget = {
    ["boolean"] = {
        ["default"] = function (parent, default, name)
            local checkbox = vgui.Create("DCheckBoxLabel", parent)
            checkbox:SetText("")
            checkbox:SetValue(default or false)
            checkbox:Dock(TOP)

            checkbox.OnChange = function(self, value)
                hook.Run("rptools_template_ui_value_change", name, value)
            end

            return checkbox
            
        end
    },
    ["number"] = {
        ["default"] = function (parent, default, name)
            local numberEntry = vgui.Create("DNumberWang", parent)
            numberEntry:SetValue(default or 0)
            numberEntry:SetTall(30)
            numberEntry:SetMinMax(0, 65635)
            numberEntry:Dock(TOP)

            numberEntry.OnValueChanged = function (self, value)
                hook.Run("rptools_template_ui_value_change", name, value)
            end

            return numberEntry
        end
    },
    ["string"] = {
        ["default"] = function (parent, default, name)
            local textEntry = vgui.Create("DTextEntry", parent)
            textEntry:SetText(default or "")
            textEntry:SetTall(30)
            textEntry:SetUpdateOnType(true)
            textEntry:Dock(TOP)

            textEntry.OnValueChange = function (self, value)
                hook.Run("rptools_template_ui_value_change", name, value)
            end

            return textEntry
        end,
        ["short"] = function (parent, default, name)
            local textEntry = vgui.Create("DTextEntry", parent)
            textEntry:SetText(default or "")
            textEntry:SetTall(30)
            textEntry:SetUpdateOnType(true)
            textEntry:Dock(TOP)

            textEntry.OnValueChange = function (self, value)
                hook.Run("rptools_template_ui_value_change", name, value)
            end

            return textEntry
        end,
        ["long"] = function (parent, default, name)
            local textEntry = vgui.Create("DTextEntry", parent)
            textEntry:SetText(default or "")
            textEntry:SetMultiline(true)
            textEntry:SetTall(80)
            textEntry:SetUpdateOnType(true)
            textEntry:Dock(TOP)

            textEntry.OnValueChange = function (self, value)
                hook.Run("rptools_template_ui_value_change", name, value)
            end

            return textEntry
        end
    }
}


local function makeParameters(parameters, frame)
    local parametersPanel = vgui.Create("DScrollPanel", frame)

    parametersPanel:DockMargin(10, 0, 10, 0)
    parametersPanel:Dock(FILL)

    local valueContainers = {}

    for _, parameter in ipairs(parameters) do
        local parameterPanel = vgui.Create("DPanel", parametersPanel)
        parameterPanel.Paint = function () end
        parameterPanel:DockMargin(0, 5, 0, 5)
        parameterPanel:Dock(TOP)

        local label = vgui.Create("DLabel", parameterPanel)
        label:SetTall(15)
        label:SetText(string.NiceName(parameter.name) .. (parameter.required and " *" or ""))
        label:Dock(TOP)

        local entry = displayWidget[parameter.type][parameter.display or "default"](parameterPanel, parameter.default, parameter.name)

        parameterPanel:InvalidateLayout(true)
        parameterPanel:SizeToChildren(false, true)

        valueContainers[parameter.name] = entry
    end

    return valueContainers

end

local function nonEmptyOrNil(value)
    if isstring(value) and value == "" then 
        return nil
    else
        return value
    end
end

local function openPanel(template, creationPos)
    local frame = makeFrame(template.name)
    makeTitle(string.NiceName(template.name), frame)
    makeDescription(template.description, frame)
    makeSeparator(frame)
    local submitButton = makeSubmitButton(frame)
    makeParameters(template.parameters, frame)

    local arguments = {}
    local finalArguments = {}
    
    hook.Add("rptools_template_ui_value_change", frame, function (_, name, newValue)
        print(newValue)
        arguments[name] = nonEmptyOrNil(newValue)
        local newFinalArguments = RPTools.Templating.ApplyParameters(template, arguments)
        submitButton:SetEnabled(finalArguments ~= nil)
        if newFinalArguments == nil then
            finalArguments = {}
            submitButton:SetEnabled(false)
        else
            finalArguments = newFinalArguments
            submitButton:SetEnabled(true)
        end
    end)

    submitButton.DoClick = function (self)

        RPTools.Network.SendToServer(RPTools.Network.MSG_TYPE.CREATE_FROM_TEMPLATE, function ()
            net.WriteString(template.name)
            net.WriteTable(finalArguments)
            net.WriteVector(creationPos)
        end)

    end

end

concommand.Add("rptools_menu", function (ply, cmd, args, argStr)
    local templateName = args[1]
    if templateName == nil or templateName == "" then
        print("Please provide a template name, see rptools_template_list")
    end

    local template = RPTools.Templating.GetTemplateFromClientCache(templateName)
    if not template then
        print("Couldn't find template " .. templateName)
        return
    end

    openPanel(template, LocalPlayer():GetEyeTrace().HitPos)
end)