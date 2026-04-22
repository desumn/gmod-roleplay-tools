RPTools = RPTools or {}

---@class RPToolsMessageAction
---@field target "player"
---@field action "send_message"
---@field message string

---@class RPToolsHUDMessageAction
---@field target "player"
---@field action "hud_message"
---@field message string
---@field duration number

---@class RPToolsPlaySoundAction
---@field target "player"
---@field action "play_sound"
---@field sound string
---@field volume? number
---@field pitch? number

---@alias RPToolsPlayerAction RPToolsMessageAction | RPToolsHUDMessageAction | RPToolsPlaySoundAction

local Client = {}

util.AddNetworkString("RPTools_MessageAction")
util.AddNetworkString("RPTools_HUDMessageAction")
util.AddNetworkString("RPTools_PlaySoundAction")

---@param action RPToolsMessageAction|RPToolsBroadcastAction
---@param ply Player
function Client.sendMessage(action, ply)
  net.Start("RPTools_MessageAction")
  net.WriteString(action.message)
  net.Send(ply)
end

---@param action RPToolsHUDMessageAction
---@param ply Player
function Client.sendHUDMessage(action, ply)
  net.Start("RPTools_HUDMessageAction")
  net.WriteString(action.message)
  net.WriteUInt(action.duration, 8)
  net.Send(ply)
end

---@param action RPToolsPlaySoundAction
---@param ply Player
function Client.sendPlaySound(action, ply)
  net.Start("RPTools_PlaySoundAction")
  net.WriteString(action.sound)
  net.WriteFloat(action.volume)
  net.WriteUInt(action.pitch, 8)
  net.Send(ply)
end

---@param action RPToolsPlayerAction
---@param ply Player
---@param node RPToolsNodeEntity
local function executePlayerAction(action, ply, node)
  if action.action == "send_message" then
    Client.sendMessage(action, ply)
  elseif action.action == "hud_message" then
    Client.sendHUDMessage(action, ply)
  elseif action.action == "play_sound" then
    action.volume = action.volume or 1
    action.pitch = action.pitch or 100
    Client.sendPlaySound(action, ply)
  else
    error("Unhandled player action " .. action.action)
  end
end

---@class RPToolsPlaySoundWorldAction
---@field target "world"
---@field action "play_sound"
---@field sound string
---@field volume? number
---@field pitch? number
---@field level? number

---@class RPToolsLoopSoundAction
---@field target "world"
---@field action "loop_sound"
---@field sound string
---@field iterations? integer
---@field volume? number
---@field pitch? number
---@field level? number

---@alias RPToolsWorldAction RPToolsPlaySoundWorldAction | RPToolsLoopSoundAction

---@param action RPToolsWorldAction
---@param node RPToolsNodeEntity
local function executeWorldAction(action, node)
  if action.action == "play_sound" then
    node:EmitSound(action.sound, action.level or 75, action.pitch or 100, action.volume or 1)
    table.insert(node.activeSounds, action.sound)
  elseif action.action == "loop_sound" then
    local ent = ents.Create("ent_rptools_loop_sound")
    ent:SetPos(node:GetPos())
    ent:SetParent(node)
    ---@cast ent RPToolsLoopSoundEntity
    ent.play_sound = {
      iterations = action.iterations,
      sound = action.sound,
      pitch = action.pitch or 100,
      volume = action.volume or 1,
      level = action.level or 75,
    }
    ent:Spawn()
  else
    error("Unhandled player action " .. action.action)
  end
end

---@class RPToolsBroadcastMessageAction
---@field target "broadcast"
---@field action "send_message"
---@field message string

---@alias RPToolsBroadcastAction RPToolsBroadcastMessageAction

---@param action RPToolsBroadcastAction
---@param node RPToolsNodeEntity
local function executeBroadcastAction(action, node)
  for _, ply in ipairs(player.GetAll()) do
    if action.action == "send_message" then
      Client.sendMessage(action, ply)
    else
      error("Unhandled player action " .. action.action)
    end
  end
end

---@class RPToolsStateSetAction
---@field target "state"
---@field action "set"
---@field scope RPToolsStateScope
---@field key string
---@field value boolean|number|string
---@field valueType "boolean"|"number"|"string"
---@field duration number?

---@class RPToolsStateRemoveAction
---@field target "state"
---@field action "remove"
---@field scope RPToolsStateScope
---@field key string

---@alias RPToolsStateAction RPToolsStateSetAction | RPToolsStateRemoveAction

---@param action RPToolsStateAction
---@param ply? Player
---@param node RPToolsNodeEntity
local function executeStateAction(action, ply, node)
  if action.action == "set" then
    RPTools.State.Server.Set(action.scope, action.key, action.value, ply, action.duration)
  elseif action.action == "remove" then
    RPTools.State.Server.Remove(action.scope, action.key, ply)
  else
    error("Unhandled player action " .. action.action)
  end
end

---@alias RPToolsAction RPToolsPlayerAction | RPToolsWorldAction | RPToolsBroadcastAction | RPToolsStateAction

---@param actions RPToolsAction[]
---@param players Player[]
---@param node RPToolsNodeEntity
local function execute(actions, players, node)
  for _, action in ipairs(actions) do
    if action.target == "player" then
      ---@cast action RPToolsPlayerAction
      for _, ply in ipairs(players) do
        executePlayerAction(action, ply, node)
      end
    elseif action.target == "world" then
      ---@cast action RPToolsWorldAction
      executeWorldAction(action, node)
    elseif action.target == "broadcast" then
      ---@cast action RPToolsBroadcastAction
      executeBroadcastAction(action, node)
    elseif action.target == "state" then
      ---@cast action RPToolsStateAction
      if action.scope == RPTools.State.Shared.SCOPE.GLOBAL then
        executeStateAction(action, nil, node)
      else
        for _, ply in ipairs(players) do
          executeStateAction(action, ply, node)
        end
      end
    else
      error("uknown target " .. action.target)
    end
  end
end

---@param node RPToolsNodeEntity
local function stopContinuous(node)
  if node.activeSounds then
    for _, sound in ipairs(node.activeSounds) do
      node:StopSound(sound)
    end
    node.activeSounds = {}
  end
  for _, child in ipairs(node:GetChildren()) do
    if IsValid(child) then
      child:Remove()
    end
  end
end

RPTools.Actions = {}
RPTools.Actions.Server = {
  Execute = execute,
  StopContinuous = stopContinuous,
}
