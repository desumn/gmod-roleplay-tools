TOOL.Category = "RPTools"
TOOL.Name = "State Condition"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
  scope = "1",
  key = "",
  type = "boolean",
  min = "0",
  max = "10",
  exclusiveMin = "0",
  exclusiveMax = "0",
  value_string = "",
  invert = "0",
  useMin = "0",
  useMax = "0",
}

if SERVER then
  util.AddNetworkString("rptools_tool_state_condition")

  net.Receive("rptools_tool_state_condition", function(_, ply)
    local entIndex = net.ReadUInt(16)
    local add = net.ReadBool()
    local scope = net.ReadUInt(2)
    local key = net.ReadString()
    local invert = net.ReadBool()
    local valueType = net.ReadString()
    local useMin = net.ReadBool()
    local useMax = net.ReadBool()
    local min = net.ReadInt(16)
    local max = net.ReadInt(16)
    local exclusiveMin = net.ReadBool()
    local exclusiveMax = net.ReadBool()
    local stringValue = net.ReadString()
    if not ply:IsAdmin() then
      return
    end

    local ent = Entity(entIndex)

    if ent:GetClass() == "ent_rptools_node" then
      ---@cast ent RPToolsNodeEntity
      if add then
        if valueType == "boolean" then
          RPTools.Transformers.AddFlagCondition(ent, scope, key, invert)
        elseif valueType == "number" then
          RPTools.Transformers.AddNumberCondition(
            ent,
            scope,
            key,
            useMin and min or nil,
            useMax and max or nil,
            { min = exclusiveMin, max = exclusiveMax }
          )
        elseif valueType == "string" then
          RPTools.Transformers.AddStringCondition(ent, scope, key, stringValue, invert)
        end
      else
        local conditionIndex = nil
        for i, condition in ipairs(ent.conditions) do
          if condition.type == "state" and condition.scope == scope and condition.key == key then
            conditionIndex = i
            break
          end
        end

        if conditionIndex then
          RPTools.Transformers.RemoveCondition(ent, conditionIndex)
        end
      end
    end
  end)
end

function TOOL:LeftClick(_)
  if CLIENT then
    local selectedIndex = RPTools.Inspector.GetSelectedEntIndex()
    if selectedIndex == nil then
      return
    end

    net.Start("rptools_tool_state_condition")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(true)
    net.WriteUInt(self:GetClientNumber("scope", 1), 2)
    net.WriteString(self:GetClientInfo("key"))
    net.WriteBool(tobool(self:GetClientBool("invert", false)))
    net.WriteString(self:GetClientInfo("type"))
    net.WriteBool(tobool(self:GetClientBool("useMin", false)))
    net.WriteBool(tobool(self:GetClientBool("useMax", false)))
    net.WriteInt(self:GetClientNumber("min", 0), 16)
    net.WriteInt(self:GetClientNumber("max", 10), 16)
    net.WriteBool(tobool(self:GetClientBool("exclusiveMin", false)))
    net.WriteBool(tobool(self:GetClientBool("exclusiveMax", false)))
    net.WriteString(self:GetClientInfo("value_string"))
    net.SendToServer()
    return true
  end
end

function TOOL:RightClick(_)
  if CLIENT then
    local selectedIndex = RPTools.Inspector.GetSelectedEntIndex()
    if selectedIndex == nil then
      return
    end
    net.Start("rptools_tool_state_condition")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(false)
    net.WriteUInt(self:GetClientNumber("scope", 1), 2)
    net.WriteString(self:GetClientInfo("key"))
    net.WriteBool(tobool(self:GetClientBool("invert", false)))
    net.WriteString(self:GetClientInfo("type"))
    net.WriteBool(tobool(self:GetClientBool("useMin", false)))
    net.WriteBool(tobool(self:GetClientBool("useMax", false)))
    net.WriteInt(self:GetClientNumber("min", 0), 16)
    net.WriteInt(self:GetClientNumber("max", 10), 16)
    net.WriteBool(tobool(self:GetClientBool("exclusiveMin", false)))
    net.WriteBool(tobool(self:GetClientBool("exclusiveMax", false)))
    net.WriteString(self:GetClientInfo("value_string"))
    net.SendToServer()
    return true
  end
end

function TOOL:Reload(_)
  if CLIENT then
    -- vide la sélection via une API de l'inspecteur
    RPTools.Inspector.ClearSelection()
    return false
  end
end

function TOOL:Holster()
  if CLIENT then
    if self.debugActive then
      LocalPlayer():ConCommand("rptools_debug")
      self.debugActive = false
    end
  end
end

function TOOL:Think()
  if CLIENT then
    if not self.debugActive then
      LocalPlayer():ConCommand("rptools_debug")
      self.debugActive = true
    end
  end
end

if CLIENT then
  function TOOL:DrawToolScreen(width, height)
    surface.SetDrawColor(20, 20, 20, 255)
    surface.DrawRect(0, 0, width, height)

    local scope = self:GetClientNumber("scope", 1)
    local scopeName = scope == 1 and "player" or "global"
    local key = self:GetClientInfo("key")
    local valueType = self:GetClientInfo("type")
    local invert = self:GetClientBool("invert", false)

    draw.SimpleText(
      "State Condition",
      "DermaLarge",
      width / 2,
      height * 0.15,
      Color(180, 180, 180),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    local keyDisplay = scopeName .. "." .. (key == "" and "?" or key)
    if #keyDisplay > 26 then
      keyDisplay = string.sub(keyDisplay, 1, 26) .. "..."
    end

    draw.SimpleText(
      keyDisplay,
      "DermaDefault",
      width / 2,
      height * 0.4,
      Color(240, 235, 230),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    local detail = ""
    if valueType == "boolean" then
      detail = invert and "= false" or "= true"
    elseif valueType == "number" then
      local useMin = self:GetClientBool("useMin", false)
      local useMax = self:GetClientBool("useMax", false)
      local parts = {}
      if useMin then
        local excl = self:GetClientBool("exclusiveMin", false)
        local min = self:GetClientNumber("min", 0)
        table.insert(parts, (excl and "> " or "≥ ") .. min)
      end
      if useMax then
        local excl = self:GetClientBool("exclusiveMax", false)
        local max = self:GetClientNumber("max", 0)
        table.insert(parts, (excl and "< " or "≤ ") .. max)
      end
      detail = #parts > 0 and table.concat(parts, " and ") or "(no bounds)"
    elseif valueType == "string" then
      local value = self:GetClientInfo("value_string")
      detail = (invert and "≠ " or "= ") .. '"' .. value .. '"'
    end

    if #detail > 26 then
      detail = string.sub(detail, 1, 26) .. "..."
    end

    draw.SimpleText(
      detail,
      "DermaDefault",
      width / 2,
      height * 0.6,
      Color(180, 180, 180),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    draw.SimpleText(
      "Type: " .. valueType,
      "DermaDefault",
      width / 2,
      height * 0.8,
      Color(120, 120, 120),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    draw.SimpleText(
      "Configure in menu",
      "DermaDefault",
      width / 2,
      height * 0.95,
      Color(120, 120, 120),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )
  end

  ---@param panel DForm
  function TOOL.BuildCPanel(panel)
    panel:Help("Add a state condition to selected node.")

    local scopeCombo = panel:ComboBox("Scope", "rptools_state_condition_scope")
    scopeCombo:AddChoice("Player", "1")
    scopeCombo:AddChoice("Global", "2")

    panel:TextEntry("Key", "rptools_state_condition_key")

    local typeCombo = panel:ComboBox("Value type", "rptools_state_condition_type")
    typeCombo:AddChoice("Boolean", "boolean")
    typeCombo:AddChoice("Number", "number")
    typeCombo:AddChoice("String", "string")

    -- Boolean / String
    local invertCheckbox = panel:CheckBox("Invert (not equals)", "rptools_state_condition_invert")

    -- Number
    local useMinCheckbox = panel:CheckBox("Minimum?", "rptools_state_condition_useMin")
    local minSlider = panel:NumSlider("Minimum", "rptools_state_condition_min", -1000, 1000, 2)
    local exclusiveMinCheckbox = panel:CheckBox("Exclusive minimum (>)", "rptools_state_condition_exclusiveMin")

    local useMaxCheckbox = panel:CheckBox("Maximum?", "rptools_state_condition_useMax")
    local maxSlider = panel:NumSlider("Maximum", "rptools_state_condition_max", -1000, 1000, 2)
    local exclusiveMaxCheckbox = panel:CheckBox("Exclusive maximum (<)", "rptools_state_condition_exclusiveMax")

    -- String
    local stringEntry = panel:TextEntry("Value (string)", "rptools_state_condition_value_string")

    local function updateEnabled()
      local typeValue = GetConVar("rptools_state_condition_type"):GetString()
      local isBool = typeValue == "boolean"
      local isNumber = typeValue == "number"
      local isString = typeValue == "string"

      invertCheckbox:SetEnabled(isBool or isString)

      useMinCheckbox:SetEnabled(isNumber)
      minSlider:SetEnabled(isNumber and GetConVar("rptools_state_condition_useMin"):GetBool())
      exclusiveMinCheckbox:SetEnabled(isNumber and GetConVar("rptools_state_condition_useMin"):GetBool())

      useMaxCheckbox:SetEnabled(isNumber)
      maxSlider:SetEnabled(isNumber and GetConVar("rptools_state_condition_useMax"):GetBool())
      exclusiveMaxCheckbox:SetEnabled(isNumber and GetConVar("rptools_state_condition_useMax"):GetBool())

      stringEntry:SetEnabled(isString)
    end

    updateEnabled()

    cvars.AddChangeCallback("rptools_state_condition_type", function()
      if IsValid(invertCheckbox) then
        updateEnabled()
      end
    end, "rptools_state_condition_type_watcher")

    cvars.AddChangeCallback("rptools_state_condition_useMin", function()
      if IsValid(minSlider) then
        updateEnabled()
      end
    end, "rptools_state_condition_useMin_watcher")

    cvars.AddChangeCallback("rptools_state_condition_useMax", function()
      if IsValid(maxSlider) then
        updateEnabled()
      end
    end, "rptools_state_condition_useMax_watcher")
  end
end
