TOOL.Category = "RPTools"
TOOL.Name = "Line of Sight"
TOOL.Command = nil
TOOL.ConfigName = ""

if SERVER then
  util.AddNetworkString("rptools_tool_line_of_sight")

  net.Receive("rptools_tool_line_of_sight", function(_, ply)
    local entIndex = net.ReadUInt(16)
    local add = net.ReadBool()
    if not ply:IsAdmin() then
      return
    end

    local ent = Entity(entIndex)

    if ent:GetClass() == "ent_rptools_node" then
      ---@cast ent RPToolsNodeEntity
      if add then
        RPTools.Transformers.AddLineOfSight(ent, true)
      else
        local conditionIndex = nil
        for i, condition in ipairs(ent.conditions) do
          if condition.test == "line_of_sight" then
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
    net.Start("rptools_tool_line_of_sight")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(true)
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
    net.Start("rptools_tool_line_of_sight")
    net.WriteUInt(selectedIndex, 16)
    net.WriteBool(false)
    net.SendToServer()
    return true
  end
end

function TOOL:Reload(_)
    if CLIENT then
        -- vide la sélection via une API de l'inspecteur
        RPTools.Inspector.ClearSelection()
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
