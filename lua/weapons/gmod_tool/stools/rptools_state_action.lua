TOOL.Category = "RPTools"
TOOL.Name = "State Action"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
  scope = "1",
  key = "",
  shouldSet = "1",
  type = "boolean",
  value_bool = "1",
  value_number = "0",
  value_string = "",
  duration = "0",
}

if SERVER then
  util.AddNetworkString("rptools_tool_state_action")

  net.Receive("rptools_tool_state_action", function(_, ply)
    local entIndex = net.ReadUInt(16)
    local add = net.ReadBool()
    local shouldSet = net.ReadBool()
    local scope = net.ReadUInt(2)
    local key = net.ReadString()
    local valueType = net.ReadString()
    local valueBool = net.ReadBool()
    local valueNumber = net.ReadInt(16)
    local valueString = net.ReadString()
    local duration = net.ReadUInt(10)
    if not ply:IsAdmin() then
      return
    end

    local value = nil

    if valueType == "boolean" then
      value = valueBool
    elseif valueType == "number" then
      value = valueNumber
    elseif valueType == "string" then
      value = valueString
    end

    local ent = Entity(entIndex)
    if ent:GetClass() == "ent_rptools_node" then
      ---@cast ent RPToolsNodeEntity
      if add then
        if shouldSet then
          RPTools.Transformers.AddStateSet(ent, scope, key, value, duration ~= 0 and duration or nil)
        else
          RPTools.Transformers.AddStateRemove(ent, scope, key)
        end
      else
        local actionType = shouldSet and "set" or "remove"
        local stateIndex = nil
        for i, action in ipairs(ent.actions) do
          if
            action.target == "state"
            and action.action == actionType
            and action.scope == scope
            and action.key == key
          then
            stateIndex = i
            break
          end
        end

        if stateIndex then
          RPTools.Transformers.RemoveAction(ent, stateIndex)
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
    net.Start("rptools_tool_state_action")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(true)
    net.WriteBool(tobool(self:GetClientBool("shouldSet", true)))
    net.WriteUInt(self:GetClientNumber("scope", 1), 2)
    net.WriteString(self:GetClientInfo("key"))
    net.WriteString(self:GetClientInfo("type"))
    net.WriteBool(tobool(self:GetClientBool("value_bool", true)))
    net.WriteInt(self:GetClientNumber("value_number", 0), 16)
    net.WriteString(self:GetClientInfo("value_string"))
    net.WriteUInt(self:GetClientNumber("duration", 0), 10)
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
    net.Start("rptools_tool_state_action")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(false)
    net.WriteBool(tobool(self:GetClientBool("shouldSet", true)))
    net.WriteUInt(self:GetClientNumber("scope", 1), 2)
    net.WriteString(self:GetClientInfo("key"))
    net.WriteString(self:GetClientInfo("type"))
    net.WriteBool(tobool(self:GetClientBool("value_bool", true)))
    net.WriteInt(self:GetClientNumber("value_number", 0), 16)
    net.WriteString(self:GetClientInfo("value_string"))
    net.WriteUInt(self:GetClientNumber("duration", 0), 10)
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

    local shouldSet = self:GetClientBool("shouldSet", true)
    local scope = self:GetClientNumber("scope", 1)
    local scopeName = scope == 1 and "player" or "global"
    local key = self:GetClientInfo("key")
    local valueType = self:GetClientInfo("type")
    local duration = self:GetClientNumber("duration", 0)

    local title = shouldSet and "Set State" or "Remove State"
    draw.SimpleText(
      title,
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

    if shouldSet then
      local valueDisplay = ""
      if valueType == "boolean" then
        valueDisplay = "= " .. tostring(self:GetClientBool("value_bool", true))
      elseif valueType == "number" then
        valueDisplay = "= " .. self:GetClientNumber("value_number", 0)
      elseif valueType == "string" then
        local value = self:GetClientInfo("value_string")
        valueDisplay = '= "' .. value .. '"'
      end

      if #valueDisplay > 26 then
        valueDisplay = string.sub(valueDisplay, 1, 26) .. "..."
      end

      draw.SimpleText(
        valueDisplay,
        "DermaDefault",
        width / 2,
        height * 0.6,
        Color(180, 180, 180),
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER
      )

      if duration > 0 then
        draw.SimpleText(
          "for " .. duration .. "s",
          "DermaDefault",
          width / 2,
          height * 0.75,
          Color(120, 120, 120),
          TEXT_ALIGN_CENTER,
          TEXT_ALIGN_CENTER
        )
      end
    end

    draw.SimpleText(
      "Configure in menu",
      "DermaDefault",
      width / 2,
      height * 0.9,
      Color(120, 120, 120),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )
  end
  ---@param panel DForm
  function TOOL.BuildCPanel(panel)
    panel:Help("Add a state action (set or remove) to selected node.")

    local shouldSetCheckbox = panel:CheckBox("Set (uncheck to remove)", "rptools_state_action_shouldSet")

    local scopeCombo = panel:ComboBox("Scope", "rptools_state_action_scope")
    scopeCombo:AddChoice("Player", "1")
    scopeCombo:AddChoice("Global", "2")

    panel:TextEntry("Key", "rptools_state_action_key")

    local typeCombo = panel:ComboBox("Value type", "rptools_state_action_type")
    typeCombo:AddChoice("Boolean", "boolean")
    typeCombo:AddChoice("Number", "number")
    typeCombo:AddChoice("String", "string")

    local boolCheckbox = panel:CheckBox("Value (bool)", "rptools_state_action_value_bool")
    local numberSlider = panel:NumSlider("Value (number)", "rptools_state_action_value_number", -1000, 1000, 2)
    local stringEntry = panel:TextEntry("Value (string)", "rptools_state_action_value_string")

    local durationSlider = panel:NumSlider("Duration (s, 0 = infinite)", "rptools_state_action_duration", 0, 3600, 0)

    local function updateEnabled()
      local shouldSet = GetConVar("rptools_state_action_shouldSet"):GetBool()
      local typeValue = GetConVar("rptools_state_action_type"):GetString()

      typeCombo:SetEnabled(shouldSet)
      boolCheckbox:SetEnabled(shouldSet and typeValue == "boolean")
      numberSlider:SetEnabled(shouldSet and typeValue == "number")
      stringEntry:SetEnabled(shouldSet and typeValue == "string")
      durationSlider:SetEnabled(shouldSet)
    end

    updateEnabled()

    cvars.AddChangeCallback("rptools_state_action_shouldSet", function()
      if IsValid(shouldSetCheckbox) then
        updateEnabled()
      end
    end, "rptools_state_action_shouldSet_watcher")

    cvars.AddChangeCallback("rptools_state_action_type", function()
      if IsValid(boolCheckbox) then
        updateEnabled()
      end
    end, "rptools_state_action_type_watcher")
  end
end
