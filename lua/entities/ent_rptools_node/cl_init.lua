include("shared.lua")

local spriteMat = Material("sprites/light_glow02_add")

local beamMat = Material("sprites/light_glow02_add")

local activeColor = Color(0, 230, 255)
local inactiveColor = Color(255, 180, 50)

function ENT:Draw()
    if not LocalPlayer():GetNW2Bool("rptools_debug", false) then return end
    
    local pos = self:GetPos()
    local isActive = self:GetNW2Bool("rptools_active", false)
    local color = isActive and activeColor or inactiveColor
    
    local ringColor = ColorAlpha(color_black, 180)
    local beamColor = RPTools.Inspector.IsSelected(self) and Color(100, 50, 150) or color
    
    render.SetMaterial(spriteMat)
    render.DrawSprite(pos, 48, 48, color)
    
    local mins, maxs = self:GetCollisionBounds()
    if maxs.x > 0 then
        render.DrawWireframeBox(pos, Angle(0, 0, 0), mins, maxs, color, false)
    end
    
    render.SetMaterial(Material("sprites/sent_ball"))
    render.DrawSprite(pos, 24, 24, ringColor)
    render.SetMaterial(spriteMat)
    render.DrawSprite(pos, 48, 48, color)
    
    local beamLength = 150
    local normal = self:GetNW2Vector("rptools_normal", Vector(0, 0, 1))
    local beamEnd = pos + normal * beamLength
    
    render.SetMaterial(beamMat)
    render.DrawBeam(pos, beamEnd, 12, 0, 1, beamColor)
    
end