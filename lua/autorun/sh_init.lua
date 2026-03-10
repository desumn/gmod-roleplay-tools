
RPTools = RPTools or {}

PIXEL = PIXEL or {}

local function loadAddon()

    if SERVER then 
        include("sv_init.lua")
    end

    if CLIENT then 
        include("cl_init.lua")
    end

    include("sh_commands.lua")

end

if PIXEL.UI then
    loadAddon()
    return
end

hook.Add("PIXEL.UI.FullyLoaded", "RPTools.WaitForPixelUI", loadAddon)