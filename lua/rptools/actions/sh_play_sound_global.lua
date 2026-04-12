if SERVER then
  RPTools.Actions.Server.RegisterClientAction("play_sound_global", function(params)
    return istable(params)
        and isstring(params.sound)
        and RPTools.Utilities.IsNumber(params.pitch)
        and RPTools.Utilities.IsNumber(params.volume)
  end, function(params)
    return "play sound: " .. params.sound .. " (v:" .. params.volume .. ", p:" .. params.pitch .. ")"
  end)
end

if CLIENT then
  RPTools.Actions.Client.RegisterAction("play_sound_global", function(params)
    LocalPlayer():EmitSound(params.sound, 0, params.pitch, params.volume)
  end)
end
