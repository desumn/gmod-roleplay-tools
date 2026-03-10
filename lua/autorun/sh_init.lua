
RPTools = RPTools or {}

PIXEL = PIXEL or {}

local function loadAddon()

    AddCSLuaFile("sh_config.lua")
    include("sh_config.lua")
    if SERVER then 
        include("sv_init.lua")
    end

    if CLIENT then 
        include("cl_init.lua")
    end


end

loadAddon()

