
AddCSLuaFile("autorun/sh_rptools_init.lua")

if SERVER then
    include("rptools/state/sv_state.lua")
end

concommand.Add("rptools_test_spawn", function(ply)
    if CLIENT then return end
    if SERVER then
        local tr = ply:GetEyeTrace()
        local ent = ents.Create("ent_rptools_node")
        ent:SetPos(tr.HitPos)
        ent:Spawn()
    end
end)