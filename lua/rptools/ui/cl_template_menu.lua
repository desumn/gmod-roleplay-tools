RPTools = RPTools or {}
RPTools.UI = RPTools.UI or {}

RPTools.UI.CurrentTemplate = ""
RPTools.UI.CurrentParams = {}

function RPTools.UI.BuildTemplateList(panel)
  local templateList = vgui.Create("DListView", panel)
  templateList:SetTall(150)
  templateList:SetMultiSelect(false)
  templateList:SetSortable(true)
  
  local nameColumn = templateList:AddColumn("Name")
  templateList:AddColumn("Description")
  
  templateList.OnSizeChanged = function(self, width, height)
    nameColumn:SetFixedWidth(width * 0.3)
  end
  
  local templates = RPTools.Templating.GetAllTemplates()
  
  for _, template in pairs(templates) do
    local line = templateList:AddLine(string.NiceName(template.name), string.NiceName(template.description))
    line.name = template.name
  end
  
  panel:AddItem(templateList)
  
  return templateList
end

---@param panel TOOL
---@param template RPToolsTemplate
---@param widgetTable table
function RPTools.UI.BuildTemplateForm(panel, template, widgetTable)
  for _, element in ipairs(widgetTable) do
    if IsValid(element) then
      element:Remove()
    end
  end
  
  table.Empty(widgetTable)
  
  local title = vgui.Create("DLabel")
  title:SetText(string.upper(template.name))
  title:SetFont("DermaLarge")
  title:SetColor(Color(255, 255, 255))
  title:SetTall(30)
  title:SetContentAlignment(5)
  
  title.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(50, 100, 150, 255))
  end
  
  title:DockMargin(5, 10, 5, 10)
  
  panel:AddItem(title)
  
  table.insert(widgetTable, title)
  
  local desc = vgui.Create("DLabel")
  desc:SetText(string.NiceName(template.description) .. "\n")
  desc:SetFont("Trebuchet18")
  desc:SetTextColor(Color(60, 60, 60))
  desc:SetWrap(true)
  desc:SetAutoStretchVertical(true)
  
  desc:DockMargin(10, 5, 10, 15)
  
  desc:SetTextInset(10, 10)
  
  desc.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 15))
  end
  
  panel:AddItem(desc)
  table.insert(widgetTable, desc)
  
  local groups = {}
  
  for name, parameter in pairs(template.parameters) do
    groups[parameter.group] = groups[parameter.group] or {}
    
    table.insert(groups[parameter.group], { name = name, param = parameter })
  end
  
  if groups["trigger"] then
    RPTools.UI.BuildParameterGroup(panel, "trigger", groups["trigger"], widgetTable)
  end
  
  if groups["action"] then
    RPTools.UI.BuildParameterGroup(panel, "action", groups["action"], widgetTable)
  end
  
  for groupName, params in pairs(groups) do
    if groupName == "action" or groupName == "trigger" then
      continue
    end
    RPTools.UI.BuildParameterGroup(panel, groupName, params, widgetTable)
  end
end

---@param panel TOOL
---@param groupName string
---@param params RPToolsParameter[]
---@param widgetTable table
function RPTools.UI.BuildParameterGroup(panel, groupName, params, widgetTable)
  local category = vgui.Create("DCollapsibleCategory")
  category:SetLabel(string.NiceName(groupName))
  category:SetExpanded(1)
  category:DockMargin(10, 15, 10, 0)
  category:Dock(TOP)
  
  local parametersList = vgui.Create("DListLayout")
  
  parametersList:DockPadding(15, 10, 5, 10)
  
  parametersList.Paint = function(self, w, h)
    draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 8))
    
    surface.SetDrawColor(100, 150, 200, 255)
    surface.DrawRect(0, 0, 3, h)
  end
  
  category:SetContents(parametersList)
  
  local required = {}
  local nonRequired = {}
  
  for _, parameter in pairs(params) do
    if parameter.param.required then
      table.insert(required, parameter)
    else
      table.insert(nonRequired, parameter)
    end
  end
  
  for _, param in ipairs(required) do
    RPTools.UI.BuildParameterWidget(parametersList, param)
  end
  
  for _, param in ipairs(nonRequired) do
    RPTools.UI.BuildParameterWidget(parametersList, param)
  end
  
  panel:AddItem(category)
  table.insert(widgetTable, category)
end

local widgetBuilders = {}
widgetBuilders["string"] = {}
widgetBuilders["boolean"] = {}
widgetBuilders["number"] = {}

local function parameterTitle(row, parameter)
  local label = vgui.Create("DLabel", row)
  label:Dock(TOP)
  label:DockMargin(0, 0, 0, 5)
  label:SetDark(true)
  label:SetFont("DermaDefaultBold")
  label:SetTextColor(Color(30, 30, 30))
  
  local titleText = string.NiceName(parameter.name) .. ((parameter.required and " *") or "")
  label:SetText(titleText)
  
  return label
end

widgetBuilders["string"]["short"] = function(row, name, parameter)
  row:SetTall(55)
  
  local label = parameterTitle(row, parameter)
  
  local entry = vgui.Create("DTextEntry", row)
  entry:Dock(TOP)
  entry:SetUpdateOnType(true)
  entry:SetTall(25)
  
  entry.OnValueChange = function(self, value)
    hook.Run("RPTools_Template_Value_Change", name, value)
  end
  
  if parameter.default then
    entry:SetValue(parameter.default)
  end
  
  if parameter.description then
    entry:SetTooltip(parameter.description)
  end
end

widgetBuilders["string"]["long"] = function(row, name, parameter)
  row:SetTall(110)
  
  local label = parameterTitle(row, parameter)
  
  
  local entry = vgui.Create("DTextEntry", row)
  entry:Dock(FILL)
  entry:SetUpdateOnType(true)
  entry:SetMultiline(true)
  
  entry.OnValueChange = function(self, value)
    hook.Run("RPTools_Template_Value_Change", name, value)
  end
  
  entry:SetDrawLanguageID(false)
  
  if parameter.default then
    entry:SetValue(parameter.default)
  end
  if parameter.description then
    entry:SetTooltip(parameter.description)
  end
end

widgetBuilders["string"]["default"] = widgetBuilders["string"]["short"]

widgetBuilders["boolean"]["default"] = function(row, name, parameter)
  row:SetTall(30)
  
  local checkbox = vgui.Create("DCheckBoxLabel", row)
  checkbox:Dock(TOP)
  checkbox:DockMargin(0, 5, 0, 0)
  checkbox:SetDark(true)
  
  checkbox.OnChange = function(self, value)
    hook.Run("RPTools_Template_Value_Change", name, value)
  end
  
  local titleText = string.NiceName(parameter.name) .. ((parameter.required and " *") or "")
  checkbox:SetText(titleText)
  
  if parameter.description then
    checkbox:SetTooltip(parameter.description)
  end
  
  if parameter.default ~= nil then
    checkbox:SetChecked(parameter.default)
  end
end

widgetBuilders["number"]["default"] = function(row, name, parameter)
  row:SetTall(55)
  
  local label = parameterTitle(row, parameter)
  
  if parameter.min and parameter.max then
    local slider = vgui.Create("DNumSlider", row)
    slider:Dock(TOP)
    slider:SetMinMax(parameter.min, parameter.max)
    slider:SetDecimals(0)
    slider:SetDark(true)
    
    slider:SetText("")
    slider.Label:SetVisible(false)
    
    slider.Slider:Dock(FILL)
    
    slider.TextArea:Dock(RIGHT)
    slider.TextArea:SetWide(45)
    
    slider.OnValueChanged = function(self, value)
      hook.Run("RPTools_Template_Value_Change", name, value)
    end
    
    if parameter.default then
      slider:SetValue(parameter.default)
    end
    
    if parameter.description then
      slider:SetTooltip(parameter.description)
    end
  else
    local numWang = vgui.Create("DNumberWang", row)
    numWang:Dock(TOP)
    numWang:SetTall(25)
    
    numWang.OnValueChange = function(self, value)
      hook.Run("RPTools_Template_Value_Change", name, tonumber(value))
    end
    
    if parameter.min then
      numWang:SetMin(parameter.min)
    end
    if parameter.max then
      numWang:SetMax(parameter.max)
    end
    
    if parameter.default then
      numWang:SetValue(parameter.default)
    end
    
    
    if parameter.description then
      numWang:SetTooltip(parameter.description)
    end
    
  end
end

function RPTools.UI.BuildParameterWidget(panel, parameter)
  local row = vgui.Create("DPanel", panel)
  row:Dock(TOP)
  row:DockMargin(5, 5, 5, 10)
  row.Paint = function() end
  
  local param = parameter.param
  
  local builder = widgetBuilders[param.type][param.display] or widgetBuilders[param.type]["default"]
  
  builder(row, parameter.name, param)
end
