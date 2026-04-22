AddCSLuaFile("autorun/sh_rptools_init.lua")
AddCSLuaFile("rptools/actions/cl_actions.lua")
AddCSLuaFile("rptools/debug/cl_debug_sync.lua")
AddCSLuaFile("rptools/debug/cl_inspector.lua")
AddCSLuaFile("rptools/state/sh_state.lua")

RPTools = RPTools or {}

if SERVER then
  include("rptools/state/sh_state.lua")
  include("rptools/state/sv_state.lua")
  include("rptools/conditions/sv_conditions.lua")
  include("rptools/actions/sv_actions.lua")
  include("rptools/engine/sv_node.lua")
  include("rptools/transformation/sv_transformers.lua")
  include("rptools/engine/sv_dispatcher.lua")
  include("rptools/debug/sv_debug_sync.lua")
end

if CLIENT then
  include("rptools/state/sh_state.lua")
  include("rptools/actions/cl_actions.lua")
  include("rptools/debug/cl_debug_sync.lua")
  include("rptools/debug/cl_inspector.lua")
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
  ent.debug = {}
  ent.debug.hitNormal = tr.HitNormal
  ent:SetPos(tr.HitPos)
  ent:Spawn()
end)

concommand.Add("rptools_test_node_flag", function(ply)
  local tr = ply:GetEyeTrace()
  local ent = ents.Create("ent_rptools_node")
  ---@cast ent RPToolsNodeEntity
  ent.conditions = {
    { type = "spatial", test = "distance", max = 200 },
    { type = "state", scope = RPTools.State.Shared.SCOPE.PLAYER, key = "tomate", equals = true },
  }
  ent.actions = {
    { target = "player", action = "send_message", message = "Je suis une tomate" },
  }
  ent.debug = {}
  ent.debug.hitNormal = tr.HitNormal
  ent:SetPos(tr.HitPos)
  ent:Spawn()
end)

concommand.Add("rptools_test_flag", function(ply, cmd, args, argStr)
  RPTools.State.Set(RPTools.State.Shared.SCOPE.PLAYER, "tomate", true, ply)
end)

concommand.Add("rptools_test_reactive", function(ply)
  local tr = ply:GetEyeTrace()
  local ent = ents.Create("ent_rptools_node")
  ---@cast ent RPToolsNodeEntity
  ent.conditions = {
    { type = "state", scope = RPTools.State.Shared.SCOPE.PLAYER, key = "tomate", equals = true },
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
  if not ply:IsAdmin() then
    return
  end
  ply:SetNW2Bool("rptools_debug", not ply:GetNW2Bool("rptools_debug", false))

  local debugActive = ply:GetNW2Bool("rptools_debug")

  if debugActive then
    for _, ent in ipairs(ents.FindByClass("ent_rptools_node")) do
      ---@cast ent RPToolsNodeEntity
      RPTools.Sync.Sync({ ply }, ent)
    end
  else
    for _, ent in ipairs(ents.FindByClass("ent_rptools_node")) do
      ---@cast ent RPToolsNodeEntity
      RPTools.Sync.RemoveSync({ ply }, ent:EntIndex())
    end
  end
end)

hook.Add("CanTool", "rptools_tool_check_admin", function(ply, trace, toolname)
  if string.StartsWith(toolname, "rptools_") then
    if not ply:IsAdmin() then
      return false
    end
  end
end)

hook.Add("PlayerDisconnected", "rptools_node_runtime_cleanup", function(ply)
  local steamid = ply:SteamID64()
  for _, node in ipairs(ents.FindByClass("ent_rptools_node")) do
    ---@cast node RPToolsNodeEntity
    node:ClearPlayerRuntimeState(steamid)
  end
end)