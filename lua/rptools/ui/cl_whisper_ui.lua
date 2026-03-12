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

hook.Add("HUDPaint", "rptools_whisper_ui", function ()
    for entid, whispers in pairs(RPTools.Whispers.Cache) do
        local ent = Entity(entid)
        if not ent:IsValid() then continue end
        
    end
end)