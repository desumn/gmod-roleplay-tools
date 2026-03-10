
RPTools = RPTools or {}

PIXEL = PIXEL or {}

local function loadAddon()

    include("rptools/sh_config.lua")
    if SERVER then 
        include("sv_init.lua")
    end

    if CLIENT then 
        include("cl_init.lua")
    end

    include("sh_commands.lua")

end

loadAddon()