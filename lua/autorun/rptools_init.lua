RPTools = RPTools or {}

---@type string
RPTools.VERSION = "0.2.1"

AddCSLuaFile("autorun/rptools_init.lua")

local function loadActions()
  local actionsFiles = file.Find("rptools/actions/sh_*.lua", "LUA")
  for _, f in ipairs(actionsFiles) do
    AddCSLuaFile("rptools/actions/" .. f)
    include("rptools/actions/" .. f)
  end
end

local function loadSources()
  local sourcesFiles = file.Find("rptools/sources/sh_*.lua", "LUA")
  for _, f in ipairs(sourcesFiles) do
    AddCSLuaFile("rptools/sources/" .. f)
    include("rptools/sources/" .. f)
  end
end

local function loadTemplates()
  local templateFiles = file.Find("rptools/templates/templates/sh_*.lua", "LUA")
  for _, f in ipairs(templateFiles) do
    AddCSLuaFile("rptools/templates/templates/" .. f)
    include("rptools/templates/templates/" .. f)
  end
end

local function loadAddon()
  AddCSLuaFile("rptools/core/sh_logs.lua")
  AddCSLuaFile("rptools/core/sh_utilities.lua")
  AddCSLuaFile("rptools/commands/sh_commands.lua")
  AddCSLuaFile("rptools/templates/sh_template_validation.lua")
  AddCSLuaFile("rptools/templates/sh_template_register.lua")
  AddCSLuaFile("rptools/templates/sh_template_helpers.lua")
  AddCSLuaFile("rptools/network/sh_network.lua")
  AddCSLuaFile("rptools/network/cl_network.lua")
  AddCSLuaFile("rptools/debug/cl_debug.lua")
  AddCSLuaFile("rptools/ui/cl_template_menu.lua")
  AddCSLuaFile("rptools/engine/sh_node_state.lua")
  AddCSLuaFile("rptools/commands/sh_saving.lua")
  AddCSLuaFile("rptools/commands/sh_attributes.lua")
  AddCSLuaFile("rptools/commands/sh_flags.lua")
  AddCSLuaFile("rptools/commands/sh_counter.lua")
  AddCSLuaFile("rptools/actions/cl_actions.lua")

  include("rptools/core/sh_logs.lua")
  include("rptools/core/sh_utilities.lua")
  include("rptools/network/sh_network.lua")

  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, "Init", "Starting shared")
  if SERVER then
    include("rptools/network/sv_network.lua")
    include("rptools/data/sv_operators.lua")
    include("rptools/sources/sv_sources.lua")
    include("rptools/data/sv_conditions.lua")
    include("rptools/actions/sv_actions.lua")
    include("rptools/data/sv_node.lua")
    include("rptools/state/sv_blackboard.lua")
    include("rptools/state/sv_node_register.lua")
    include("rptools/engine/sh_node_state.lua")
    include("rptools/engine/sv_coordinator.lua")
    include("rptools/debug/sv_debug.lua")
    include("rptools/templates/sh_template_validation.lua")
    include("rptools/templates/sh_template_register.lua")
    include("rptools/templates/sh_template_helpers.lua")
    include("rptools/state/sv_serialization.lua")
    include("rptools/commands/sh_commands.lua")
    include("rptools/commands/sh_saving.lua")
    include("rptools/commands/sh_attributes.lua")
    include("rptools/commands/sh_flags.lua")
    include("rptools/commands/sh_counter.lua")
  end

  if CLIENT then
    include("rptools/network/cl_network.lua")
    include("rptools/actions/cl_actions.lua")
    include("rptools/engine/sh_node_state.lua")
    include("rptools/debug/cl_debug.lua")
    include("rptools/templates/sh_template_validation.lua")
    include("rptools/templates/sh_template_register.lua")
    include("rptools/templates/sh_template_helpers.lua")
    include("rptools/ui/cl_template_menu.lua")
    include("rptools/commands/sh_commands.lua")
    include("rptools/commands/sh_saving.lua")
    include("rptools/commands/sh_attributes.lua")
    include("rptools/commands/sh_flags.lua")
    include("rptools/commands/sh_counter.lua")
  end

  loadSources()
  loadActions()
  loadTemplates()
end

loadAddon()
