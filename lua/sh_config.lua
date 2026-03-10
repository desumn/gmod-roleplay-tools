RPTools = RPTools or {}
RPTools.Config = RPTools.Config or {}

-- How far does an entity need to be to send its whispers?
RPTools.Config.WhisperDistance = 300

-- How long does a whisper stays on screen?
RPTools.Config.WhisperDuration = 10


-- If not "", which sound to play when a player receive a whisper?
RPTools.Config.WhisperSound = "ambient/wind/wind_snippet1.wav"

-- Which colors does the whisper dialog take?
RPTools.Config.Colors = {
    Background = function (alpha) Color(20, 20, 30, alpha) end,
    Accent     = function (alpha) Color(180, 140, 255, alpha) end,
    Text       = function (alpha) Color(220, 220, 220, alpha) end
}


-- Which prefix is used to log?
RPTools.Config.LogPrefix = "[RPTools] "

-- How often (in seconds) do the server if a player can receive a whisper?
RPTools.Config.WhisperTickRate = 0.5

