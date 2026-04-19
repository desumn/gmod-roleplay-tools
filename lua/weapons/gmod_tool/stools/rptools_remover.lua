TOOL.Category = "RPTools"
TOOL.Name = "Node Remover"
TOOL.Command = nil
TOOL.ConfigName = ""

if SERVER then
  util.AddNetworkString("rptools_tool_remove")

  net.Receive("rptools_tool_remove", function(_, ply)
    local entIndex = net.ReadUInt(16)
    if not ply:IsAdmin() then
      return
    end

    local ent = Entity(entIndex)

    if ent:GetClass() == "ent_rptools_node" then
        ent:Remove()
    end
  end)
end

function TOOL:LeftClick(_)
  if CLIENT then
    local selectedIndex = RPTools.Inspector.GetSelectedEntIndex()
    if selectedIndex == nil then
      return
    end
    net.Start("rptools_tool_remove")
    net.WriteUInt(selectedIndex, 16)
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

        draw.SimpleText("Remove", "DermaLarge",
            width / 2, height * 0.4,
            Color(255, 100, 100),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        draw.SimpleText("Left click to delete", "DermaDefault",
            width / 2, height * 0.65,
            Color(180, 180, 180),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end
