AddCSLuaFile("autorun/sh_rptools_init.lua")
AddCSLuaFile("rptools/actions/cl_actions.lua")

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
