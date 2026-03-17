
RPTools = RPTools or {}

AddCSLuaFile("autorun/sh_init.lua")

local function loadAddon()

    AddCSLuaFile("rptools/core/sh_logs.lua")
    AddCSLuaFile("rptools/core/sh_utilities.lua")
    AddCSLuaFile("rptools/commands/sh_commands.lua")
    AddCSLuaFile("rptools/commands/sh_templating.lua")
    AddCSLuaFile("rptools/network/sh_network.lua")
    AddCSLuaFile("rptools/network/cl_network.lua")
    AddCSLuaFile("rptools/debug/cl_debug.lua")

    include("rptools/core/sh_logs.lua")
    include("rptools/core/sh_utilities.lua")
    include("rptools/network/sh_network.lua")
    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, "Init", "Starting shared")
    if SERVER then
        include("rptools/network/sv_network.lua")
        include("rptools/data/sv_operators.lua")
        include("rptools/data/sv_sources.lua")
        include("rptools/data/sv_conditions.lua")
        include("rptools/data/sv_actions.lua")
        include("rptools/data/sv_node.lua")
        include("rptools/state/sv_blackboard.lua")
        include("rptools/state/sv_node_register.lua")
        include("rptools/engine/sv_coordinator.lua")
        include("rptools/debug/sv_debug.lua")
        include("rptools/templates/sv_templating.lua")
        include("rptools/templates/sv_default_templates.lua")
    end

    if CLIENT then
        include("rptools/network/cl_network.lua")
        include("rptools/debug/cl_debug.lua")
    end

    include("rptools/commands/sh_commands.lua")
    include("rptools/commands/sh_templating.lua")


end

loadAddon()

