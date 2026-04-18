TOOL.Category = "RPTools"
TOOL.Name = "Node Placer"
TOOL.Command = nil
TOOL.ConfigName = ""

function TOOL:LeftClick(trace)
  if CLIENT then
    return true
  end

  local ent = ents.Create("ent_rptools_node")
  ---@cast ent RPToolsNodeEntity
  ent.conditions = {}
  ent.actions = {}
  ent.debug = { hitNormal = trace.HitNormal }
  ent:SetPos(trace.HitPos)

  if IsValid(trace.Entity) and not trace.Entity:IsWorld() then
    ent:SetParent(trace.Entity)
  end

  ent:Spawn()
  return true
end

---@param trace TraceResult
function TOOL:RightClick(trace)
  if CLIENT then
    return true
  end

  local candidates = ents.FindInSphere(trace.HitPos, 3)

  if #candidates == 1 then
    local ent = candidates[1]
    if IsValid(ent) and ent:GetClass() == "ent_rptools_node" then
      ent:Remove()
      return true
    end
  end
  return false
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
