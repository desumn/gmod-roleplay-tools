RPTools = RPTools or {}

---@type table<number, RPToolsDebugNodeInfos>
local nodes = {}

net.Receive("rptools_sync_debug", function ()
    ---@type RPToolsDebugNodeInfos
    local node = net.ReadTable()
    nodes[node.entIndex] = node
end)

net.Receive("rptools_sync_remove", function()
    local entIndex = net.ReadUInt(16)
    nodes[entIndex] = nil
end)

---@param entIndex number
---@return RPToolsDebugNodeInfos?
local function getNode(entIndex)
    return nodes[entIndex]
end

---@return table<number, RPToolsDebugNodeInfos>
local function getAll()
    return nodes
end

RPTools.Node = RPTools.Node or {}
RPTools.Node.Client = {
    GetNode = getNode,
    GetAll = getAll
}

concommand.Add("rptools_print_debug", function(ply)
  PrintTable(RPTools.Node.Client.GetAll())
end)
