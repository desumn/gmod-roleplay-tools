
RPTools = RPTools or {}
RPTools.NodeRegister = RPTools.NodeRegister or {}

local logModuleName = "NodeRegister"

local nodeRegister = {}


function RPTools.NodeRegister.registerNode(node)
    local isvalid, error_message = RPTools.Node.validateNode(node)
    if not isvalid then
        RPTools.Logs.log(RPTools.Logs.level.warning, logModuleName, "Tried to register an invalid node (" .. error_message .. ")")
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

    if not node then return end

    local error_message = RPTools.Node.edit(node, subNode)

    if error_message then
        RPTools.Logs.log(RPTools.Logs.level.warning, logModuleName, "Failed to edit node with id:(" .. id .. "): " .. error_message)
    end

    nodeRegister[id] = node

    RPTools.Logs.log(RPTools.Logs.level.info, logModuleName, "Edited node with id:(" .. id .. ")")
end
