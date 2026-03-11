

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

RPTools.UI.registerList = RPTools.UI.registerList or {}

RPTools.UI.WhisperDuration = RPTools.Config.WhisperDuration
RPTools.UI.WhisperSound = RPTools.Config.WhisperSound
RPTools.UI.LastWhisperTime = nil
RPTools.UI.WhisperStack = {}

net.Receive("show_whispers", function (_, ply)
    local whispers = net.ReadTable(true)
    RPTools.UI.WhisperEntity = net.ReadEntity()
    
    local shouldStartTimer = not RPTools.UI.WhisperStack[1]

    for _, whisper in ipairs(whispers) do
        table.insert(RPTools.UI.WhisperStack, whisper)
    end

    if shouldStartTimer then
        RPTools.UI.LastWhisperTime = RealTime()
        if whispers[1].soundUrl and whispers[1].soundUrl ~= "" then
            surface.PlaySound(whispers[1].soundUrl)
        else
            surface.PlaySound(RPTools.Config.WhisperSound)
        end
    end

end)

hook.Add( "HUDPaint", "RPTools_DrawWhisperUI", function()

    if not RPTools.UI.WhisperStack[1] then
        RPTools.UI.WhisperEntity = nil
        return
     end

    local elapsed = RealTime() - RPTools.UI.LastWhisperTime

    local whisper = RPTools.UI.WhisperStack[1]

    if elapsed > whisper.duration then
        table.remove(RPTools.UI.WhisperStack, 1)
        RPTools.UI.LastWhisperTime = RealTime()
        return
    end

    local alpha = 255

    if elapsed < 0.5 then
        alpha = (elapsed / 0.5) * 255
    elseif elapsed > whisper.duration - 1 then
        alpha = ((whisper.duration - elapsed) / 1) * 255
    end

    local tag = RPTools.UI.registerList[whisper.required_tag]

    local bgColor = RPTools.Config.Colors.Background(alpha * 0.8)
    local tagColor = ColorAlpha(tag.colour, alpha)
    local textColor = RPTools.Config.Colors.Text(alpha)

    local tagName = string.upper(tag.name)
    local text = whisper.text

    surface.SetFont("RPTools_WhisperTag")
    local tagW, tagH = surface.GetTextSize(tagName .. " — ")

    surface.SetFont("RPTools_WhisperText")
    local textW, textH = surface.GetTextSize(text)
    local totalW = tagW + textW + 40
    local h = 36

    local x = (ScrW() - totalW) / 2
    local y = ScrH() - 80

    draw.RoundedBox(6, x, y, totalW, h, bgColor)

    draw.SimpleText(tagName .. " — ", "RPTools_WhisperTag", x + 16, y + h / 2, tagColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    draw.SimpleText(text, "RPTools_WhisperText", x + 16 + tagW, y + h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

end)


hook.Add("PreDrawHalos", "RPTools_WhisperHalo", function()
    if not RPTools.UI.WhisperEntity or not RPTools.UI.WhisperEntity:IsValid() then return end
    halo.Add({RPTools.UI.WhisperEntity}, Color(180, 140, 255), 8, 8, 2)
end)


-- Admin Toolgun ui

hook.Add("PreDrawHalos", "RPTools_WhisperToolGunHalo", function()
    
    if not LocalPlayer():IsValid() or not LocalPlayer():IsAdmin() then return end
    
    local toolgun = LocalPlayer():GetActiveWeapon()
    if not IsValid(toolgun) or (toolgun:GetClass() ~= "gmod_tool") then return end
    if toolgun:GetMode() ~= "rptools_whisper" then return end

    local entities = ents.FindInSphere(LocalPlayer():GetPos(), 2000)

    local whisperEnts = {}

    for _, ent in pairs(entities) do
        if ent:GetNW2Bool("rptools_has_whispers", false) then
            table.insert(whisperEnts, ent)
        end
    end

    halo.Add(whisperEnts, Color(180, 140, 255), 8, 8, 2, true, true)
end)


hook.Add("PostDrawTranslucentRenderables", "RPTools_WhisperRangePreview", function()
    local ply = LocalPlayer()
    if not ply:IsValid() or not ply:IsAdmin() then return end
    local weapon = ply:GetActiveWeapon()

    if not IsValid(weapon) or weapon:GetClass() ~= "gmod_tool" then return end
    local tool = ply:GetTool()
    if not tool or tool:GetMode() ~= "rptools_whisper" then return end

    local dist = weapon:GetNW2Int("RPTools_SelectedDist", 0)
    if dist <= 0 then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if IsValid(ent) and ent:GetNW2Bool("rptools_has_whispers", false) then
        local tagID = weapon:GetNW2String("RPTools_SelectedTag", "")
        local tag = RPTools.UI.registerList[tagID]
        local col = tag and tag.colour or Color(180, 140, 255)

        render.SetColorMaterial()
        render.DrawWireframeSphere(ent:GetPos(), dist, 30, 30, col, true)
        
        render.DrawSphere(ent:GetPos(), dist, 30, 30, ColorAlpha(col, 10))
    end
    
end)
