
RPTools = RPTools or {}

if sam then
    sam.permissions.add("rptools_admin", "RPTools", "admin")
end

function RPTools.CanAdmin(ply)
    if not IsValid(ply) then return false end
    if sam then return ply:HasPermission("rptools_admin") end
    return ply:IsAdmin()
end

local function loadAddon()

    AddCSLuaFile("sh_config.lua")
    include("sh_config.lua")
    if SERVER then 
        include("sv_init.lua")
    end

    if CLIENT then 
        include("cl_init.lua")
    end
    include("sh_commands.lua")


end

loadAddon()

