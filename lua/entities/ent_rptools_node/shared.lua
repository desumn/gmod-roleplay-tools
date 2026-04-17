---@class RPToolsNodeEntity : Entity
---@field conditions RPToolsCondition[]
---@field actions RPToolsAction[]
---@field playersInZone table<string, Player>
---@field activePlayers table<string, boolean>
---@field radius number
---@field activeSounds string[]
---@field CountActives fun(self : RPToolsNodeEntity) : number

AddCSLuaFile()

RPTools = RPTools or {}

ENT.Type = "anim"
ENT.Base = "base_anim"

---@param self RPToolsNodeEntity
function ENT:CountActives()
  return table.Count(self.activePlayers)
end

if SERVER then
  ---@param self RPToolsNodeEntity
  function ENT:Initialize()
    self.playersInZone = {}
    self.activePlayers = {}

    local distances = {}
    for _, condition in ipairs(self.conditions) do
      if condition.type ~= "spatial" or condition.test ~= "distance" then
        continue
      end
      local max = condition.max
      if max ~= nil then
        table.insert(distances, condition.max)
      end
    end

    self:SetModel("models/hunter/plates/plate.mdl")
    if #distances ~= 0 then
      local radius = math.max(unpack(distances))
      self:SetSolid(SOLID_BBOX)
      self:SetCollisionBounds(Vector(-radius, -radius, -radius), Vector(radius, radius, radius))
      self:SetTrigger(true)
    end
    self:SetMoveType(MOVETYPE_NONE)
    self:SetNotSolid(true)
  end

  ---@param self RPToolsNodeEntity
  function ENT:StartTouch(ent)
    if not ent:IsPlayer() then
      return
    end
    ---@cast ent Player
    self.playersInZone[ent:SteamID64()] = ent
    self:NextThink(CurTime() + 0.2)
  end

  ---@param self RPToolsNodeEntity
  function ENT:EndTouch(ent)
    if not ent:IsPlayer() then
      return
    end
    ---@cast ent Player
    self.playersInZone[ent:SteamID64()] = nil
    local oldActives = self:CountActives()
    self.activePlayers[ent:SteamID64()] = nil
    local newActives = self:CountActives()

    if newActives ~= 0 and oldActives > newActives then
      hook.Run("RPTools_PlayerDisqualified", self, ent)
    end

    if oldActives > 0 and newActives == 0 then
      hook.Run("RPTools_NodeDeactivated", self, ent)
    end
  end

  ---@param self RPToolsNodeEntity
  function ENT:Think()
    local oldActives = self:CountActives()

    ---@type Player[]
    local activations = {}
    ---@type Player[]
    local deactivations = {}
    for _, ply in pairs(self.playersInZone) do
      local steamid = ply:SteamID64()
      local conditionsSuccess, conditionsMet = pcall(RPTools.Conditions.Evaluate, self.conditions, ply, self)
      if not conditionsSuccess then
        continue
      end
      if conditionsMet and self.activePlayers[steamid] == nil then
        table.insert(activations, ply)
        self.activePlayers[ply:SteamID64()] = true
      elseif not conditionsMet and self.activePlayers[steamid] ~= nil then
        table.insert(deactivations, ply)
        self.activePlayers[ply:SteamID64()] = nil
      end
    end

    local newActives = self:CountActives()

    if oldActives == 0 and newActives > 0 then
      hook.Run("RPTools_NodeActivated", self, activations)
    end
    if oldActives > 0 and newActives == 0 then
      hook.Run("RPTools_NodeDeactivated", self)
    end
    if oldActives > 0 and #activations > 0 then
      hook.Run("RPTools_PlayersActivation", self, activations)
    end
    if newActives > 0 and #deactivations > 0 then
      hook.Run("RPTools_PlayersDeactivations", self, deactivations)
    end

    if not table.IsEmpty(self.playersInZone) then
      self:NextThink(CurTime() + 0.2)
      return true
    else
      return false
    end
  end
end

if CLIENT then
  local spriteMat = Material("sprites/light_glow02_add")
  local beamMat = Material("trails/laser")

  function ENT:Draw()
    local pos = self:GetPos()
    local radius = 200
    local color = Color(0, 230, 255)

    render.SetMaterial(spriteMat)
    render.DrawSprite(pos, 48, 48, color)

    local mins = pos + Vector(-radius, -radius, -radius)
    local maxs = pos + Vector(radius, radius, radius)
    render.DrawWireframeBox(
      pos,
      Angle(0, 0, 0),
      Vector(-radius, -radius, -radius),
      Vector(radius, radius, radius),
      color,
      false
    )
  end
end
