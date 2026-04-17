---@class RPToolsNodeEntity : Entity
---@field conditions RPToolsCondition[]
---@field actions RPToolsAction[]
---@field playersInZone table<string, Player>
---@field playersWithNewState table<string, Player>
---@field activePlayers table<string, boolean>
---@field isSpatial boolean
---@field radius number
---@field keys table<RPToolsStateScope, table<string, boolean>>
---@field activeSounds string[]
---@field shouldEvaluate boolean
---@field CountActives fun(self : RPToolsNodeEntity) : number
---@field ReevaluateState fun(self : RPToolsNodeEntity) : nil


AddCSLuaFile()

RPTools = RPTools or {}

ENT.Type = "anim"
ENT.Base = "base_anim"


if SERVER then
  ---@param self RPToolsNodeEntity
  function ENT:CountActives()
    return table.Count(self.activePlayers)
  end

  ---@param self RPToolsNodeEntity
  function ENT:ReevaluateState()
    for _, ply in ipairs(player.GetAll()) do
      self.playersWithNewState[ply:SteamID64()] = ply
    end
  end
  
  
  ---@param self RPToolsNodeEntity
  function ENT:Initialize()
    self.playersInZone = {}
    self.playersWithNewState = {}
    self.activePlayers = {}
    self.activeSounds = {}
    
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
    self.isSpatial = #distances ~= 0
    if self.isSpatial then
      local radius = math.max(unpack(distances))
      self:SetSolid(SOLID_BBOX)
      self:SetCollisionBounds(Vector(-radius, -radius, -radius), Vector(radius, radius, radius))
      self:SetTrigger(true)
      self.shouldEvaluate = true
    else
      self.keys = {
        [RPTools.State.SCOPE.GLOBAL] = {},
        [RPTools.State.SCOPE.PLAYER] = {}
      }
      for _, condition in ipairs(self.conditions) do
        if condition.type ~= "state" then
          continue
        end
        self.keys[condition.scope][condition.key] = true
      end
      self:ReevaluateState()
      self.shouldEvaluate = true
      
      RPTools.State.OnValueChange("rptools_node_" .. self:EntIndex(), function (scope, key, context, oldValue, newValue)
        if self.keys[scope][key] == nil then return end
        if scope == RPTools.State.SCOPE.GLOBAL then
          self:ReevaluateState()
        elseif scope == RPTools.State.SCOPE.PLAYER then
          self.playersWithNewState[context:SteamID64()] = context
        end
        self.shouldEvaluate = true
      end)
    end
    self:SetMoveType(MOVETYPE_NONE)
    self:SetNotSolid(true)
  end
  
  ---@param self RPToolsNodeEntity
  function ENT:StartTouch(ent)
    if not ent:IsPlayer() or not self.isSpatial then
      return
    end
    ---@cast ent Player
    self.playersInZone[ent:SteamID64()] = ent
    self:NextThink(CurTime() + 0.2)
    self.shouldEvaluate = true
  end
  
  ---@param self RPToolsNodeEntity
  function ENT:EndTouch(ent)
    if not ent:IsPlayer() or not self.isSpatial then
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
    if not self.shouldEvaluate then return end
    local oldActives = self:CountActives()
    
    local players = (self.isSpatial and self.playersInZone) or self.playersWithNewState
    
    ---@type Player[]
    local activations = {}
    ---@type Player[]
    local deactivations = {}
    for _, ply in pairs(players) do
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
    
    self.playersWithNewState = {}
    
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
    
    if table.IsEmpty(self.playersInZone) then
      self.shouldEvaluate = false
      return
    end
    self:NextThink(CurTime() + 0.2)
    return true
  end
  
  function ENT:OnRemove()
    hook.Remove("RPTools_StateValueChanged", "rptools_node_" .. self:EntIndex())
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
