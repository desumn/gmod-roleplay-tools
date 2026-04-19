TOOL.Category = "RPTools"
TOOL.Name = "View Angle"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = { angle = "30" }

if SERVER then
  util.AddNetworkString("rptools_tool_view_angle")

  net.Receive("rptools_tool_view_angle", function(_, ply)
    local entIndex = net.ReadUInt(16)
    local add = net.ReadBool()
    local angle = net.ReadUInt(8)
    if not ply:IsAdmin() then
      return
    end

    local ent = Entity(entIndex)

    if ent:GetClass() == "ent_rptools_node" then
      ---@cast ent RPToolsNodeEntity
      if add then
        RPTools.Transformers.AddViewAngle(ent, angle)
      else
        local conditionIndex = nil
        for i, condition in ipairs(ent.conditions) do
          if condition.test == "view_angle" then
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
    net.Start("rptools_tool_view_angle")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(true)
    net.WriteUInt(self:GetClientNumber("angle", 30), 8)
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
    net.Start("rptools_tool_view_angle")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(false)
    net.WriteUInt(self:GetClientNumber("angle", 30), 8)
    net.SendToServer()
    return true
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

    local angle = self:GetClientNumber("angle", 30) or 30

    draw.SimpleText(
      "View Angle",
      "DermaLarge",
      width / 2,
      height * 0.25,
      Color(180, 180, 180),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    draw.SimpleText(
      math.floor(angle) .. "°",
      "DermaLarge",
      width / 2,
      height * 0.55,
      Color(240, 235, 230),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    draw.SimpleText(
      "Configure in Props or Contextual menu",
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
    panel:Help("Adjust the view angle condition for selected node.")
    panel:NumSlider("Angle (°)", "rptools_view_angle_angle", 1, 180, 0)
  end
end
