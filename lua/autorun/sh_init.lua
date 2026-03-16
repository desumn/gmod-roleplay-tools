
RPTools = RPTools or {}

AddCSLuaFile("autorun/sh_init.lua")

local function loadAddon()

    AddCSLuaFile("rptools/sh_logs.lua")
    AddCSLuaFile("rptools/sh_utilities.lua")
    AddCSLuaFile("rptools/sh_commands.lua")
    AddCSLuaFile("rptools/sh_network.lua")
    AddCSLuaFile("rptools/cl_network.lua")
    AddCSLuaFile("rptools/cl_debug.lua")

    include("rptools/sh_logs.lua")
    include("rptools/sh_utilities.lua")
    include("rptools/sh_network.lua")
    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, "Init", "Starting shared")
    if SERVER then
        include("rptools/sv_network.lua")
        include("rptools/sv_operators.lua")
        include("rptools/sv_sources.lua")
        include("rptools/sv_conditions.lua")
        include("rptools/sv_actions.lua")
        include("rptools/sv_node.lua")
        include("rptools/sv_blackboard.lua")
        include("rptools/sv_node_register.lua")
        include("rptools/sv_coordinator.lua")
        include("rptools/sv_debug.lua")
    end

    if CLIENT then
        include("rptools/sh_network.lua")
        include("rptools/cl_network.lua")
        include("rptools/cl_debug.lua")
    end



    include("rptools/sh_commands.lua")


end

loadAddon()

