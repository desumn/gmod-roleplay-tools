if SERVER then
  RPTools.Actions.Server.RegisterClientAction("play_sound", function(params)
    return istable(params)
      and isstring(params.sound)
      and RPTools.Utilities.IsNumber(params.volume)
      and RPTools.Utilities.IsNumber(params.pitch)
  end, function(params)
    return "play sound"
      .. " (v:"
      .. tostring(params.volume)
      .. ", p:"
      .. tostring(params.pitch)
      .. "): "
      .. params.sound
  end)
end
if CLIENT then
  RPTools.Actions.Client.RegisterAction("play_sound", function(params)
    LocalPlayer():EmitSound(params.sound, 0, params.pitch, params.volume)
  end)
end
