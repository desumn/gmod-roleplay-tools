AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:Initialize()
if SERVER then
        self:SetModel("models/hunter/plates/plate.mdl")
        self:SetSolid(SOLID_BBOX)
        self:SetCollisionBounds(Vector(-200, -200, -200), Vector(200, 200, 200))
        self:SetTrigger(true)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetNotSolid(true)
    end
end

function ENT:StartTouch(ent)
    if not ent:IsPlayer() then return end
    print("Entered in radius")
end

function ENT:EndTouch(ent)
    if not ent:IsPlayer() then return end
    print("Exited from radius")
end

if CLIENT then
    local spriteMat = Material("sprites/light_glow02_add")
    local beamMat = Material("trails/laser")

    function ENT:Draw()
        local pos = self:GetPos()
        local radius = 200
        local color = Color(0, 230, 255)

        render.SetMaterial(spriteMat)
        render.DrawSprite(pos, 48, 48, color)

        local mins = pos + Vector(-radius, -radius, -radius)
        local maxs = pos + Vector(radius, radius, radius)
        render.DrawWireframeBox(pos, Angle(0, 0, 0), Vector(-radius, -radius, -radius), Vector(radius, radius, radius), color, false)
    end
end