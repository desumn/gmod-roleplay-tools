RPTools = RPTools or {}
RPTools.Config = RPTools.Config or {}

RPTools.Tags = RPTools.Tags or {}

RPTools.Tags.Type = {
    default = 1;
}

RPTools.Tags.typeName = {
    [RPTools.Tags.Type.default] = "Default";
}

-- How far does an entity need to be to send its whispers?
RPTools.Config.WhisperDistance = 300

-- How long does a whisper stays on screen?
RPTools.Config.WhisperDuration = 10


-- If not "", which sound to play when a player receive a whisper?
RPTools.Config.WhisperSound = "ambient/wind/wind_snippet1.wav"

-- Which colors does the whisper dialog take?

local accentColor = Color(24, 24, 27)

RPTools.Config.Colors = {
    Background = function(alpha) return Color(225, 225, 230, alpha or 255) end, -- Assombri (ancien: 245)
    Panel      = function(alpha) return Color(210, 210, 215, alpha or 255) end, -- Assombri (ancien: 232)
    Hover      = function(alpha) return Color(195, 195, 200, alpha or 255) end, -- Assombri (ancien: 218)
    
    Accent     = function(alpha) return ColorAlpha(accentColor, alpha or 255) end,
    
    Text       = function(alpha) return Color(25, 25, 30, alpha or 255) end,
    TextMuted  = function(alpha) return Color(100, 100, 110, alpha or 255) end,
    
    Danger     = function(alpha) return Color(220, 38, 38, alpha or 255) end
}
-- Which prefix is used to log?
RPTools.Config.LogPrefix = "[RPTools] "

RPTools.Config.BatchSendDelay = 0.2
