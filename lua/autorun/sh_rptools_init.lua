AddCSLuaFile("autorun/sh_rptools_init.lua")
AddCSLuaFile("rptools/actions/cl_actions.lua")

RPTools = RPTools or {}

if SERVER then
  include("rptools/state/sv_state.lua")
  include("rptools/conditions/sv_conditions.lua")
  include("rptools/actions/sv_actions.lua")
  include("rptools/engine/sv_dispatcher.lua")
end

if CLIENT then
  include("rptools/actions/cl_actions.lua")
end

concommand.Add("rptools_test_spawn", function(ply)
  if CLIENT then
    return
  end
  if SERVER then
    local tr = ply:GetEyeTrace()
    local ent = ents.Create("ent_rptools_node")
    ent:SetPos(tr.HitPos)
    ent:Spawn()
  end
end)

concommand.Add("rptools_test_node", function(ply)
  local tr = ply:GetEyeTrace()
  local ent = ents.Create("ent_rptools_node")
  ---@cast ent RPToolsNodeEntity
  ent.conditions = {
    { type = "spatial", test = "distance", max = 200 },
  }
  ent.actions = {
    { target = "player", action = "send_message", message = "Je mange des fruits rouges." },
  }
  ent:SetPos(tr.HitPos)
  ent:Spawn()
end)

concommand.Add("rptools_test_node_flag", function(ply)
    local tr = ply:GetEyeTrace()
    local ent = ents.Create("ent_rptools_node")
    ---@cast ent RPToolsNodeEntity
    ent.conditions = {
        { type = "spatial", test = "distance", max = 200 },
        { type = "state", scope = RPTools.State.SCOPE.PLAYER, key = "tomate", equals = true },
    }
    ent.actions = {
        { target = "player", action = "send_message", message = "Je suis une tomate" },
    }
    ent:SetPos(tr.HitPos)
    ent:Spawn()
end)

concommand.Add("rptools_test_flag", function (ply, cmd, args, argStr)
  RPTools.State.Set(RPTools.State.SCOPE.PLAYER, "tomate", true, ply)
end)

concommand.Add("rptools_test_reactive", function(ply)
    local tr = ply:GetEyeTrace()
    local ent = ents.Create("ent_rptools_node")
    ---@cast ent RPToolsNodeEntity
    ent.conditions = {
        { type = "state", scope = RPTools.State.SCOPE.PLAYER, key = "tomate", equals = true },
    }
    ent.actions = {
        { target = "player", action = "send_message", message = "Tu es une tomate" },
    }
    ent:SetPos(tr.HitPos)
    ent:Spawn()
end)


concommand.Add("rptools_test_sound", function(ply)
    local tr = ply:GetEyeTrace()
    local ent = ents.Create("ent_rptools_node")
    ---@cast ent RPToolsNodeEntity
    ent.conditions = {
        { type = "spatial", test = "distance", max = 300 },
    }
    ent.actions = {
        { target = "world", action = "play_sound", sound = "ambient/explosions/explode_1.wav", volume = 1, level = 75 },
    }
    ent:SetPos(tr.HitPos)
    ent:Spawn()
end)

concommand.Add("rptools_debug", function(ply)
    ply:SetNW2Bool("rptools_debug", not ply:GetNW2Bool("rptools_debug", false))
end)
