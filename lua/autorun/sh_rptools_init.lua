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
