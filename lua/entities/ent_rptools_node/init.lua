AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local THINK_RATE = 0.2

function ENT:CountActives()
  return table.Count(self.activePlayers)
end

function ENT:CountInZone()
  return table.Count(self.playersInZone)
end

function ENT:ReevaluateState()
  for _, ply in player.Iterator() do
    self.playersWithNewState[ply:SteamID64()] = ply
  end
end

function ENT:ClearPlayerRuntimeState(steamID)
  self.playersInZone[steamID] = nil
  self.playersWithNewState[steamID] = nil
  self.activePlayers[steamID] = nil
end

---@param self RPToolsNodeEntity
local function initSpatial(self, distances)
  local radius = math.max(unpack(distances))
  local boxMins = Vector(-radius, -radius, -radius)
  local boxMaxs = Vector(radius, radius, radius)
  self:SetCollisionBounds(boxMins, boxMaxs)
  self:SetSolid(SOLID_BBOX)
  self:SetTrigger(true)

  local newInZone = {}
  local newActivePlayers = {}
  for _, ply in ipairs(ents.FindInBox(boxMins, boxMaxs)) do
    if ply:IsPlayer() then
      ---@cast ply Player
      local steamid = ply:SteamID64()
      newInZone[steamid] = ply
      newActivePlayers[steamid] = self.activePlayers[steamid]
    end
  end
  self.playersInZone = newInZone
  self.activePlayers = newActivePlayers
end

local function extractKeys(self)
  for _, condition in ipairs(self.conditions) do
    if condition.type ~= "state" then
      continue
    end
    self.keys[condition.scope][condition.key] = true
  end
end

local function subscribeToStateChange(self)
  self.valueChangeEvent = "rptools_node_" .. self:EntIndex()
  RPTools.State.Server.OnValueChange(self.valueChangeEvent, function(scope, key, context, oldValue, newValue)
    if self.keys[scope][key] == nil then
      return
    end
    if scope == RPTools.State.Shared.SCOPE.GLOBAL then
      self:ReevaluateState()
    elseif scope == RPTools.State.Shared.SCOPE.PLAYER then
      self.playersWithNewState[context:SteamID64()] = context
    end
    self.shouldEvaluate = true
  end)
end

local function unSubscribeFromStateChange(self)
  if self.valueChangeEvent then
    hook.Remove("RPTools_StateValueChanged", self.valueChangeEvent)
  end
end

---@param self RPToolsNodeEntity
local function initReactive(self)
  self:SetSolid(SOLID_NONE)
  self.playersInZone = {}

  self.keys = {
    [RPTools.State.Shared.SCOPE.GLOBAL] = {},
    [RPTools.State.Shared.SCOPE.PLAYER] = {},
  }
  extractKeys(self)
  self.playersWithNewState = {}
  self:ReevaluateState()

  subscribeToStateChange(self)
end

local function extractDistances(self)
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
  return distances
end

---@param self RPToolsNodeEntity
function ENT:ReInitialize()
  local distances = extractDistances(self)
  unSubscribeFromStateChange(self)
  self:SetTrigger(false)

  self.isSpatial = #distances ~= 0
  if self.isSpatial then
    initSpatial(self, distances)
  else
    initReactive(self)
  end

  self.shouldEvaluate = true
end

---@param self RPToolsNodeEntity
function ENT:Initialize()
  self.playersInZone = {}
  self.playersWithNewState = {}
  self.activePlayers = {}
  self.activeSounds = {}
  self.debug = self.debug or {}
  self.state = { paused = false, errorMessage = "" }

  self:SetModel("models/hunter/plates/plate.mdl")
  self:SetMoveType(MOVETYPE_NONE)
  self:SetNotSolid(true)

  self:ReInitialize()

  hook.Run("RPTools_NodeCreated", self)
end

---@param self RPToolsNodeEntity
function ENT:StartTouch(ent)
  if not ent:IsPlayer() or not self.isSpatial then
    return
  end
  ---@cast ent Player
  self.playersInZone[ent:SteamID64()] = ent
  self:NextThink(CurTime() + THINK_RATE)
  self.shouldEvaluate = true
end

---@param self RPToolsNodeEntity
function ENT:EndTouch(ent)
  if not ent:IsPlayer() or not self.isSpatial then return end
  ---@cast ent Player
  local steamid = ent:SteamID64()
  self.playersInZone[steamid] = nil
  
  local wasActive = self.activePlayers[steamid] ~= nil
  self.activePlayers[steamid] = nil
  
  if wasActive then
    if self:CountActives() == 0 then
      hook.Run("RPTools_NodeDeactivated", self)
    else
      hook.Run("RPTools_PlayersDeactivation", self, { ent })
    end
  end
end

---@param self RPToolsNodeEntity
---@param ply Player
---@return boolean?
local function evaluatePlayerConditions(self, ply)
  local steamid = ply:SteamID64()
  local conditionsSuccess, result = pcall(RPTools.Conditions.Evaluate, self.conditions, ply, self)
  if not conditionsSuccess then
    self.state.paused = true
    self.state.errorMessage = tostring(result)
    return nil
  end
  return result
end

---@param self RPToolsNodeEntity
---@param ply Player
---@param result boolean
---@return boolean, boolean
local function evaluateActivation(self, ply, result)
  local steamid = ply:SteamID64()
  local activate, deactivate
  if result and self.activePlayers[steamid] == nil then
    activate = true
    self.activePlayers[steamid] = true
  elseif not result and self.activePlayers[steamid] ~= nil then
    deactivate = true
    self.activePlayers[steamid] = nil
  end
  return activate, deactivate
end

---@param self RPToolsNodeEntity
---@param players table<string, Player>
---@return Player[], Player[]
local function evaluatePlayersConditions(self, players)
  ---@type Player[]
  local activations = {}
  ---@type Player[]
  local deactivations = {}
  for _, ply in pairs(players) do
    local result = evaluatePlayerConditions(self, ply)

    if result == nil then
      continue
    end

    local activate, deactivate = evaluateActivation(self, ply, result)

    if activate then
      table.insert(activations, ply)
    end

    if deactivate then
      table.insert(deactivations, ply)
    end
  end
  return activations, deactivations
end

local function emitLifecycleHooks(self, oldActives, newActives, activations, deactivations)
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
    hook.Run("RPTools_PlayersDeactivation", self, deactivations)
  end
end

---@param self RPToolsNodeEntity
function ENT:Think()
  if self.state.paused or not self.shouldEvaluate then
    return
  end
  local oldActives = self:CountActives()

  local players = (self.isSpatial and self.playersInZone) or self.playersWithNewState

  local activations, deactivations = evaluatePlayersConditions(self, players)

  self.playersWithNewState = {}

  local newActives = self:CountActives()

  emitLifecycleHooks(self, oldActives, newActives, activations, deactivations)

  if table.IsEmpty(self.playersInZone) then
    self.shouldEvaluate = false
    return
  end
  self:NextThink(CurTime() + THINK_RATE)
  return true
end

function ENT:OnRemove()
  hook.Run("RPTools_NodeRemoved", self:EntIndex())
  if self.valueChangeEvent then
    hook.Remove("RPTools_StateValueChanged", self.valueChangeEvent)
  end
end
