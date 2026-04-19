TOOL.Category = "RPTools"
TOOL.Name = "Message"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
  message = "",
  hud = "0",
  duration = "5",
}

if SERVER then
  util.AddNetworkString("rptools_tool_message")

  net.Receive("rptools_tool_message", function(_, ply)
    local entIndex = net.ReadUInt(16)
    local add = net.ReadBool()
    local hud = net.ReadBool()
    local message = net.ReadString()
    local duration = net.ReadUInt(10)
    if not ply:IsAdmin() then
      return
    end

    local ent = Entity(entIndex)
    if ent:GetClass() == "ent_rptools_node" then
      ---@cast ent RPToolsNodeEntity
      if add then
        if not hud then
          RPTools.Transformers.AddMessage(ent, message)
        elseif hud then
          RPTools.Transformers.AddHUDMessage(ent, message, duration)
        end
      else
        local messageType = (hud and "hud_message") or "send_message"
        local messageIndex = nil
        for i, action in ipairs(ent.actions) do
          if action.action == messageType then
            messageIndex = i
            break
          end
        end

        if messageIndex then
          RPTools.Transformers.RemoveAction(ent, messageIndex)
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
    net.Start("rptools_tool_message")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(true)
    net.WriteBool(tobool(self:GetClientBool("hud", false)))
    net.WriteString(self:GetClientInfo("message"))
    net.WriteUInt(self:GetClientNumber("duration", 5), 10)
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
    net.Start("rptools_tool_message")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(false)
    net.WriteBool(tobool(self:GetClientBool("hud", false)))
    net.WriteString(self:GetClientInfo("message"))
    net.WriteUInt(self:GetClientNumber("duration", 5), 10)
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

    local message = self:GetClientInfo("message")
    local isHud = tobool(self:GetClientNumber("hud", 0))
    local duration = self:GetClientNumber("duration", 5)

    local title = isHud and "HUD Message" or "Chat Message"

    draw.SimpleText(
      title,
      "DermaLarge",
      width / 2,
      height * 0.2,
      Color(180, 180, 180),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    local displayMessage = message
    if #displayMessage > 30 then
      displayMessage = string.sub(displayMessage, 1, 30) .. "..."
    end
    if displayMessage == "" then
      displayMessage = "(empty)"
    end

    draw.SimpleText(
      displayMessage,
      "DermaDefault",
      width / 2,
      height * 0.45,
      Color(240, 235, 230),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    if isHud then
      draw.SimpleText(
        "Duration: " .. math.floor(duration) .. "s",
        "DermaDefault",
        width / 2,
        height * 0.65,
        Color(180, 180, 180),
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER
      )
    end

    draw.SimpleText(
      "Configure in menu",
      "DermaDefault",
      width / 2,
      height * 0.85,
      Color(120, 120, 120),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )
  end

  ---@param panel DForm
  function TOOL.BuildCPanel(panel)
    panel:Help("Add a message action to selected node.")

    local label = panel:Help("Message:")
    local messageEntry = vgui.Create("DTextEntry", panel)
    panel:AddItem(messageEntry)
    messageEntry:SetConVar("rptools_message_message")
    messageEntry:SetMultiline(true)
    messageEntry:SetTall(80)

    local hudCheckbox = panel:CheckBox("HUD message", "rptools_message_hud")
    local durationSlider = panel:NumSlider("HUD duration (s)", "rptools_message_duration", 1, 60, 0)

    local function updateEnabled()
      durationSlider:SetEnabled(GetConVar("rptools_message_hud"):GetBool())
    end

    updateEnabled()

    hudCheckbox.OnChange = function(_, _)
      updateEnabled()
    end
  end
end
