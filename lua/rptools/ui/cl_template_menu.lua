RPTools = RPTools or {}
RPTools.UI = RPTools.UI or {}

RPTools.UI.CurrentTemplate = ""

RPTools.UI.CurrentParams = {}

local function nonEmptyOrNil(value)
  if value == nil or (isstring(value) and value == "") then
    return nil
  else
    return value
  end
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
  descLabel:SetTextColor(Color(190, 195, 200))

  descLabel:SetWrap(true)
  descLabel:SetTall(60)

  descLabel:SetContentAlignment(5)
  descLabel:DockMargin(10, 0, 10, 10)
  descLabel:Dock(TOP)
  return descLabel
end

local function makeSeparator(frame)
  local separator = vgui.Create("DPanel", frame)

  separator:SetTall(2)

  separator.Paint = function(self, w, h)
    surface.SetDrawColor(Color(80, 85, 95))
    surface.DrawRect(0, 0, w, h)
  end

  separator:DockMargin(10, 5, 10, 5)
  separator:Dock(TOP)

  return separator
end

local displayWidget = {
  ["boolean"] = {
    ["default"] = function(parent, default, name)
      local checkbox = vgui.Create("DCheckBoxLabel", parent)
      checkbox:SetText("")
      checkbox:SetValue(default or false)
      checkbox:Dock(TOP)

      checkbox.OnChange = function(self, value)
        hook.Run("rptools_template_ui_value_change", name, value)
      end

      return checkbox
    end,
  },
  ["number"] = {
    ["default"] = function(parent, default, name)
      local numberEntry = vgui.Create("DNumberWang", parent)
      numberEntry:SetValue(default or 0)
      numberEntry:SetTall(30)
      numberEntry:SetMinMax(0, 65635)
      numberEntry:Dock(TOP)

      numberEntry.OnValueChanged = function(self, value)
        hook.Run("rptools_template_ui_value_change", name, value)
      end

      return numberEntry
    end,
  },
  ["string"] = {
    ["default"] = function(parent, default, name)
      local textEntry = vgui.Create("DTextEntry", parent)
      textEntry:SetText(default or "")
      textEntry:SetTall(30)
      textEntry:SetUpdateOnType(true)
      textEntry:Dock(TOP)
      textEntry:SetPlaceholderText("Please enter a " .. name)

      textEntry.OnValueChange = function(self, value)
        hook.Run("rptools_template_ui_value_change", name, value)
      end

      return textEntry
    end,
    ["short"] = function(parent, default, name)
      local textEntry = vgui.Create("DTextEntry", parent)
      textEntry:SetText(default or "")
      textEntry:SetTall(30)
      textEntry:SetUpdateOnType(true)
      textEntry:Dock(TOP)
      textEntry:SetPlaceholderText("Please enter a " .. name)

      textEntry.OnValueChange = function(self, value)
        hook.Run("rptools_template_ui_value_change", name, value)
      end

      return textEntry
    end,
    ["long"] = function(parent, default, name)
      local textEntry = vgui.Create("DTextEntry", parent)
      textEntry:SetText(default or "")
      textEntry:SetMultiline(true)
      textEntry:SetTall(80)
      textEntry:SetUpdateOnType(true)
      textEntry:Dock(TOP)
      textEntry:SetPlaceholderText("Please enter a " .. name)

      textEntry.OnValueChange = function(self, value)
        hook.Run("rptools_template_ui_value_change", name, value)
      end

      return textEntry
    end,
  },
}

local function makeParameters(parameters, frame)
  local valueContainers = {}

  for _, parameter in ipairs(parameters) do
    local parameterPanel = vgui.Create("DPanel", frame)
    parameterPanel.Paint = function() end
    parameterPanel:DockMargin(5, 8, 5, 8)
    parameterPanel:Dock(TOP)

    local label = vgui.Create("DLabel", parameterPanel)
    label:SetTall(15)
    label:SetText(string.NiceName(parameter.name) .. (parameter.required and " (Required)" or " (Optional)"))
    if parameter.required then
      label:SetTextColor(Color(230, 180, 80))
    else
      label:SetTextColor(Color(150, 155, 160))
    end
    label:Dock(TOP)

    local entry =
      displayWidget[parameter.type][parameter.display or "default"](parameterPanel, parameter.default, parameter.name)

    parameterPanel:InvalidateLayout(true)
    local height = label:GetTall() + entry:GetTall() + 12
    parameterPanel:SetTall(height)

    valueContainers[parameter.name] = entry
  end

  return valueContainers
end

function RPTools.UI.OpenTemplateMenu(frame, template)
  frame:Clear()
  makeTitle(string.NiceName(template.name), frame)
  makeDescription(template.description, frame)
  makeSeparator(frame)
  makeParameters(template.parameters, frame)

  local arguments = {}

  local stateIndicator = vgui.Create("DLabel", frame)
  stateIndicator:SetFont("DermaDefault")
  stateIndicator:SetText("Template not valid - please fill the required parameters.")
  stateIndicator:SetTextColor(Color(220, 160, 170))

  stateIndicator:SetWrap(true)
  stateIndicator:SetTall(60)

  stateIndicator:SetContentAlignment(5)
  stateIndicator:DockMargin(8, 0, 8, 10)
  stateIndicator:Dock(TOP)

  hook.Add("rptools_template_ui_value_change", frame, function(_, name, newValue)
    arguments[name] = nonEmptyOrNil(newValue)
    local newFinalArguments = RPTools.Templating.ApplyParameters(template, arguments)

    if newFinalArguments then
      RPTools.UI.CurrentParams = newFinalArguments
      RPTools.UI.CurrentTemplate = template.name
      stateIndicator:SetText("Template valid - you can now place a node in world. ")
      stateIndicator:SetTextColor(Color(100, 200, 100))
    else
      RPTools.UI.CurrentParams = {}
      RPTools.UI.CurrentTemplate = ""
      stateIndicator:SetText("Template not valid - please fill the required parameters.")
      stateIndicator:SetTextColor(Color(220, 160, 170))
    end
  end)
end
