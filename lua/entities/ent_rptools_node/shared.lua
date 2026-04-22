---@alias SteamID64 string

---@class RPToolsNodeEntity : Entity
---@field ReInitialize fun(self : RPToolsNodeEntity)
---@field conditions RPToolsCondition[]
---@field actions RPToolsAction[]
---@field private playersInZone table<SteamID64, Player>
---@field private playersWithNewState table<SteamID64, Player>
---@field private activePlayers table<SteamID64, boolean>
---@field private isSpatial boolean
---@field private keys table<RPToolsStateScope, table<string, boolean>>
---@field private activeSounds string[]
---@field private shouldEvaluate boolean
---@field private valueChangeEvent string
---@field state { paused : boolean, errorMessage : string }
---@field debug { hitNormal? : Vector }

RPTools = RPTools or {}

ENT.Type = "anim"
ENT.Base = "base_anim"
