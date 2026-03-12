surface.CreateFont("RPTools_WhisperTag", {
    font = "Roboto",
    size = 22,
    weight = 700,
})

surface.CreateFont("RPTools_WhisperText", {
    font = "Roboto",
    size = 20,
    weight = 400,
})

RPTools.UI = RPTools.UI or {}
RPTools.UI.Whispers = RPTools.UI.Whispers or {}

RPTools.UI.registerList = RPTools.UI.registerList or {}

RPTools.UI.Context = {
    c2D = 1;
    c3D = 2;
}

function RPTools.UI.wordWrap(text, font, maxWidth)
    surface.SetFont(font)
    local exploded = string.Explode(" ", text)
    local lines = {}
    local currentLine = ""

    for _, word in ipairs(exploded) do
        local potentialLine = currentLine .. word .. " "
        local textWidth, _ = surface.GetTextSize(potentialLine)
        if textWidth > maxWidth then
            table.insert(lines, currentLine)
            currentLine = word .. " "
        else
            currentLine = potentialLine
        end
    end

    table.insert(lines, currentLine)
    return lines
end

function RPTools.UI.Whispers.isLookingAt(ply, ent, tolerance)
    local aimVector = ply:GetAimVector()
    local dirToEnt = (ent:WorldSpaceCenter() - ply:EyePos()):GetNormalized()
    local dot = aimVector:Dot(dirToEnt)

    return dot > tolerance
end

local function DrawObservationWhisper2D(ent, whisper, tagData, yOffset)
    local pos2D = ent:WorldSpaceCenter():ToScreen()
    
    if not pos2D.visible then return yOffset end

    local diamondSize = 6
    local poly = {
        { x = pos2D.x, y = pos2D.y - diamondSize },
        { x = pos2D.x + diamondSize, y = pos2D.y },
        { x = pos2D.x, y = pos2D.y + diamondSize },
        { x = pos2D.x - diamondSize, y = pos2D.y }
    }
    
    draw.NoTexture()
    surface.SetDrawColor(tagData.colour)
    surface.DrawPoly(poly)

    local ply = LocalPlayer()
    local isLooking = RPTools.UI.Whispers.isLookingAt(ply, ent, 0.98)
    
    if not isLooking then return yOffset end

    local headerFont = "RPTools_WhisperTag"
    local textFont = "RPTools_WhisperText"
    
    local panelWidth = 350
    local padding = 15
    local textMaxWidth = panelWidth - (padding * 2) - 10 

    local lines = RPTools.UI.wordWrap(whisper.text, textFont, textMaxWidth)
    
    surface.SetFont(headerFont)
    local _, headerHeight = surface.GetTextSize("[" .. tagData.name .. "]")
    
    surface.SetFont(textFont)
    local _, lineHeight = surface.GetTextSize("A")
    
    local panelHeight = padding + headerHeight + 5 + (#lines * lineHeight) + padding
    
    local drawX = ScrW() - panelWidth - 50
    local drawY = (ScrH() / 2) - (panelHeight / 2) + yOffset 
    
    draw.RoundedBox(4, drawX, drawY, panelWidth, panelHeight, Color(20, 20, 20, 220))
    
    draw.RoundedBoxEx(4, drawX, drawY, 4, panelHeight, tagData.colour, true, false, true, false)
    
    draw.SimpleText("[" .. tagData.name .. "]", headerFont, drawX + padding + 5, drawY + padding, tagData.colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    local textStartY = drawY + padding + headerHeight + 5
    for i, line in ipairs(lines) do
        draw.SimpleText(line, textFont, drawX + padding + 6, textStartY + ((i - 1) * lineHeight) + 1, Color(0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(line, textFont, drawX + padding + 5, textStartY + ((i - 1) * lineHeight), color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    return yOffset + panelHeight + 10
end

local Renderers = {}

Renderers[RPTools.Tags.Type.observation] = {
    context = RPTools.UI.Context.c2D;
    draw = DrawObservationWhisper2D;
    check = function(_, _, whisper, distSqr)
        return distSqr <= (whisper.distance ^ 2)
    end
}

hook.Add("HUDPaint", "RPTools_DrawWhispers2D", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local eyePos = ply:EyePos()

    for entid, whispers in pairs(RPTools.Whispers.Cache) do
        local ent = Entity(entid)
        if not ent:IsValid() then continue end
        
        local distSqr = eyePos:DistToSqr(ent:GetPos())
        local whispersToDraw = {}

        for _, whisper in ipairs(whispers) do
            local tagData = RPTools.UI.registerList[whisper.required_tag]
            if not tagData then continue end
            
            local router = Renderers[tagData.type]
            
            if router and router.context == RPTools.UI.Context.c2D and router.check(ply, ent, whisper, distSqr) then
                table.insert(whispersToDraw, {whisper = whisper, tag = tagData, router = router})
            end
        end

        if #whispersToDraw > 1 then
            table.sort(whispersToDraw, function(a, b) 
                return a.whisper.distance > b.whisper.distance 
            end)
        end

        local currentYOffset = 0
        for _, item in ipairs(whispersToDraw) do
            currentYOffset = item.router.draw(ent, item.whisper, item.tag, currentYOffset)
        end
    end
end)

