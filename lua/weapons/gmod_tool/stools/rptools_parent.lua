TOOL.Category = "RPTools"
TOOL.Name = "Parent"
TOOL.Command = nil
TOOL.ConfigName = ""

if SERVER then
  util.AddNetworkString("rptools_tool_parent")

  net.Receive("rptools_tool_parent", function(_, ply)
    local entIndex = net.ReadUInt(16)
    local makeParent = net.ReadBool()
    local parentIndex = net.ReadUInt(16)
    if not ply:IsAdmin() then
      return
    end

    local ent = Entity(entIndex)
    local parent = Entity(parentIndex)

    if not IsValid(parent) then return end

    if ent:GetClass() == "ent_rptools_node" then
        ---@cast ent RPToolsNodeEntity
        if makeParent then
            RPTools.Transformers.SetParent(ent, parent)
        else
            RPTools.Transformers.RemoveParent(ent)
        end
    end
  end)
end

---@param trace TraceResult
function TOOL:LeftClick(trace)
  if CLIENT then
    local selectedIndex = RPTools.Inspector.GetSelectedEntIndex()
    if selectedIndex == nil then
      return
    end
    if not IsValid(trace.Entity) then return end

    net.Start("rptools_tool_parent")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(true)
    net.WriteUInt(trace.Entity:EntIndex(), 16)
    net.SendToServer()
    return true
  end
end

---@param trace TraceResult
function TOOL:RightClick(trace)
  if CLIENT then
    local selectedIndex = RPTools.Inspector.GetSelectedEntIndex()
    if selectedIndex == nil then
      return
    end

    net.Start("rptools_tool_parent")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(false)
    net.WriteUInt(0, 16)
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

        draw.SimpleText("Parent", "DermaLarge",
            width / 2, height * 0.4,
            Color(255, 100, 100),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        draw.SimpleText("Left click to make parent, right blick to remove parent", "DermaDefault",
            width / 2, height * 0.65,
            Color(180, 180, 180),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end
