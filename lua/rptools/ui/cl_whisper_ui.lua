

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
        surface.PlaySound(RPTools.UI.WhisperSound)
    end

end)

hook.Add( "HUDPaint", "RPTools_DrawWhisperUI", function()

    if not RPTools.UI.WhisperStack[1] then
        RPTools.UI.WhisperEntity = nil
        return
     end

    local elapsed = RealTime() - RPTools.UI.LastWhisperTime

    local whisper = RPTools.UI.WhisperStack[1]

    if elapsed > RPTools.UI.WhisperDuration then
        table.remove(RPTools.UI.WhisperStack, 1)
        RPTools.UI.LastWhisperTime = RealTime()
        return
    end

    local alpha = 255

    if elapsed < 0.5 then
        alpha = (elapsed / 0.5) * 255
    elseif elapsed > RPTools.UI.WhisperDuration - 1 then
        alpha = ((RPTools.UI.WhisperDuration - elapsed) / 1) * 255
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