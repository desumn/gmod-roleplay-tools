RPTools = RPTools or {}

---@class RPToolsPlayerAction
---@field target "player"
---@field action "send_message"|"hud_message"|"play_sound"
---@field message? string
---@field duration? number
---@field sound? string
---@field volume? number
---@field pitch? number

local Client = {}

util.AddNetworkString("RPTools_MessageAction")
util.AddNetworkString("RPTools_HUDMessageAction")
util.AddNetworkString("RPTools_PlaySoundAction")

---@param action RPToolsPlayerAction|RPToolsBroadcastAction
---@param ply Player
function Client.sendMessage(action, ply)
    net.Start("RPTools_MessageAction")
    net.WriteString(action.message)
    net.Send(ply)
end

---@param action RPToolsPlayerAction
---@param ply Player
function Client.sendHUDMessage(action, ply)
    net.Start("RPTools_HUDMessageAction")
    net.WriteString(action.message)
    net.WriteUInt(action.duration, 8)
    net.Send(ply)
end

---@param action RPToolsPlayerAction
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
        Client.sendPlaySound(action, ply)
    end
    
end

---@class RPToolsWorldAction
---@field target "world"
---@field action "play_sound"|"loop_sound"
---@field sound? string
---@field iterations? integer
---@field volume? number
---@field pitch? number
---@field level? number

---@param action RPToolsWorldAction
---@param node RPToolsNodeEntity
local function executeWorldAction(action, node)
    if action.action == "play_sound" then
        node:EmitSound(action.sound, action.level or 75, action.pitch or 100, action.volume or 1)
    elseif action.action == "loop_sound" then
        local ent = ents.Create("ent_rptools_loop_sound")
        ent:SetPos(node:GetPos())
        ent:SetParent(node)
        
        ent.play_sound = {
            iteration = action.iterations,
            sound = action.sound,
            pitch = action.pitch or 100,
            volume = action.volume or 1,
            level = action.level or 75,
        }
        
        ent:Spawn()
    end
end


---@class RPToolsBroadcastAction
---@field target "broadcast"
---@field action "send_message"
---@field message string

---@param action RPToolsBroadcastAction
---@param node RPToolsNodeEntity
local function executeBroadcastAction(action, node)
    for _, ply in ipairs(player.GetAll()) do
        if action.action == "send_message" then
            Client.sendMessage(action, ply)
        end
    end
end

---@class RPToolsStateAction
---@field target "state"
---@field action "set"|"remove"
---@field scope RPToolsStateScope
---@field key string
---@field value? any
---@field duration? number

---@param action RPToolsStateAction
---@param ply? Player
---@param node RPToolsNodeEntity
local function executeStateAction(action, ply, node)
    if action.action == "set" then
        RPTools.State.Set(action.scope, action.key, action.value, ply, action.duration)
    elseif action.action == "remove" then
        RPTools.State.Remove(action.scope, action.key, ply)
    end
end

---@alias RPToolsAction RPToolsPlayerAction | RPToolsWorldAction | RPToolsBroadcastAction | RPToolsStateAction

---@param actions RPToolsAction[]
---@param players Player[]
---@param node RPToolsNodeEntity
local function execute(actions, players, node)
    for _, action in ipairs(actions) do
        if action.target == "player" then
            for _, ply in ipairs(players) do
                executePlayerAction(action, ply, node)
            end
        elseif action.target == "world" then
            executeWorldAction(action, node)
        elseif action.target == "broadcast" then
            executeBroadcastAction(action, node)
        elseif action.target == "state" then
            if action.scope == RPTools.State.SCOPE.GLOBAL then
                executeStateAction(action, nil, node)
            else
                for _, ply in ipairs(players) do
                    executeStateAction(action, ply, node)
                end
            end
        end
    end
end

local function stopContinuous(node)
    for _, child in ipairs(node:GetChildren()) do
        if IsValid(child) then
            child:Remove()
        end
    end
end

RPTools.Actions.Server = {
    Execute = execute,
    StopContinuous = stopContinuous
}