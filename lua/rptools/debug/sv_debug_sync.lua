RPTools = RPTools or {}

util.AddNetworkString("rptools_sync_debug")
util.AddNetworkString("rptools_sync_remove")


---@return Player[]
local function listTargets()
    local adminsDebug = {}
    for _, ply in ipairs(player.GetAll()) do
        local debugActive = ply:GetNW2Bool("rptools_debug", false)
        if ply:IsAdmin() and debugActive then
            table.insert(adminsDebug, ply)
        end
    end
    return adminsDebug
end

---@class RPToolsDebugNodeInfos
---@field entIndex number
---@field conditions RPToolsCondition[]
---@field actions RPToolsAction[]
---@field state { paused : boolean, errorMessage : string }
---@field activePlayers number
---@field playersInZone number

---@param targets Player[]
---@param node RPToolsNodeEntity
local function sync(targets, node)
    ---@type RPToolsDebugNodeInfos
    local debugNode = {
        entIndex = node:EntIndex(),
        conditions = table.Copy(node.conditions),
        actions = table.Copy(node.actions),
        state = node.state,
        activePlayers = node:CountActives(),
        playersInZone = node:CountInZone(),
    }

    net.Start("rptools_sync_debug")
    net.WriteTable(debugNode)
    net.Send(targets)
end

---@param targets Player[]
---@param entIndex number
local function removeSync(targets, entIndex)
    net.Start("rptools_sync_remove")
    net.WriteUInt(entIndex, 16)
    net.Send(targets)
end

RPTools.Node.OnCreate("rptools_sync_on_create", function(node)
    sync(listTargets(), node)
end)

RPTools.Node.OnActivation("rptools_sync_on_activation", function(node, players)
    sync(listTargets(), node)
end)

RPTools.Node.OnDeactivation("rptools_sync_on_deactivation", function(node)
    sync(listTargets(), node)
end)

RPTools.Node.OnPlayersActivation("rptools_sync_on_players_activation", function(node, players)
    sync(listTargets(), node)
end)

RPTools.Node.OnPlayersDeactivation("rptools_sync_on_players_deactivation", function(node, players)
    sync(listTargets(), node)
end)

RPTools.Node.OnRemove("rptools_sync_on_remove", function (entIndex)
    removeSync(listTargets(), entIndex)
end)

RPTools.Sync = {
    Sync = sync,
    RemoveSync = removeSync
}