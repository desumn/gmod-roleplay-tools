
RPTools = RPTools or {}

local function loadAddon()


    include("sh_logs.lua")
    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, "Init", "Starting server")
    if SERVER then 
        include("sv_init.lua")
    end

    if CLIENT then 
        include("cl_init.lua")
    end

end

loadAddon()

