---@class RPToolsNodeEntity : Entity
---@field ReInitialize fun(self : RPToolsNodeEntity)
---@field conditions RPToolsCondition[]
---@field actions RPToolsAction[]
---@field playersInZone table<string, Player>
---@field playersWithNewState table<string, Player>
---@field activePlayers table<string, boolean>
---@field isSpatial boolean
---@field radius number
---@field keys table<RPToolsStateScope, table<string, boolean>>
---@field activeSounds string[]
---@field shouldEvaluate boolean
---@field CountActives fun(self : RPToolsNodeEntity) : number
---@field CountInZone fun(self : RPToolsNodeEntity) : number
---@field ReevaluateState fun(self : RPToolsNodeEntity) : nil
---@field debug { hitNormal : Vector }
---@field state { paused : boolean, errorMessage : string}

RPTools = RPTools or {}

ENT.Type = "anim"
ENT.Base = "base_anim"
