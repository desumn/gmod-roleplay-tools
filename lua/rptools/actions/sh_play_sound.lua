if SERVER then
  RPTools.Actions.Server.RegisterClientAction("play_sound", function(params)
    return istable(params)
        and isstring(params.sound)
        and RPTools.Utilities.IsNumber(params.volume)
        and RPTools.Utilities.IsNumber(params.pitch)
        and RPTools.Utilities.IsNumber(params.level)
        and isvector(params.position)
  end, function(params)
    return "play sound: " .. params.sound .. " (v:" .. params.volume .. ", p:" .. params.pitch .. ", l:" .. params.level .. ")"
  end)
end
if CLIENT then
  RPTools.Actions.Client.RegisterAction("play_sound", function(params)
    sound.Play(params.sound, params.position, params.level, params.pitch, params.volume)
  end)
end
