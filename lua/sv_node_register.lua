
RPTools = RPTools or {}
RPTools.NodeRegister = RPTools.NodeRegister or {}

local logModuleName = "NodeRegister"

local nodeRegister = {}


function RPTools.NodeRegister.registerNode(node)
    if not RPTools.Node.CheckValidity(node) then
        RPTools.Logs.log(RPTools.Logs.level.warning, logModuleName, "Tried to register an invalid node (" .. table.ToString(node) .. ")")
        return
    end

    local id = RPTools.Node.getId(node) or RPTools.Node.generateId(node)

    nodeRegister[id] = node
    RPTools.Logs.log(RPTools.Logs.level.info, logModuleName, "Added node with id:(" .. id .. ") to the node register.")
    -- Hook pour prévenir de l'ajout?
end

function RPTools.NodeRegister.unregisterNode(id)
    if not nodeRegister[id] then
        RPTools.Logs.log(RPTools.Logs.level.warning, logModuleName, "Trying to remove node: node (" .. table.ToString(node) .. ") not found")
        return
    end
    nodeRegister[id] = nil
    RPTools.Logs.log(RPTools.Logs.level.info, logModuleName, "Removed node with id:(" .. id .. ") from the node register.")
    -- Hook pour prévenir de la suppression?
end

function RPTools.NodeRegister.getNodeById(id)
    local node = nodeRegister[id]
    if not node then
        RPTools.Logs.log(RPTools.Logs.level.warning, logModuleName, "Trying to get node: node (" .. table.ToString(node) .. ") not found")
        return
    end

    return node
end

function RPTools.NodeRegister.getAllNodes()
    return nodeRegister
end

function RPTools.NodeRegister.editNode(id, subNode)
    local node = RPTools.NodeRegister.getNodeById(id)
    local fieldName = fieldName or ""

    if not node then return end

    local id = RPTools.Node.getId(node)

    local testNode = table.Copy(node)

    table.Merge(testNode, subNode)

    if not RPTools.Node.CheckValidity(testNode) then
        RPTools.Logs.log(RPTools.Logs.level.warning, logModuleName, "Failed to edit node with id:(" .. id .. ") from " .. table.ToString(node) .. " to " .. table.ToString(testNode))
        return
    end

    table.Merge(node, subNode)
    nodeRegister[id] = node

    RPTools.Logs.log(RPTools.Logs.level.info, logModuleName, "Edited node with id:(" .. id .. ")")
end
