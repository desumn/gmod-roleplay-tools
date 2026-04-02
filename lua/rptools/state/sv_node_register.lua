
RPTools = RPTools or {}
RPTools.NodeRegister = RPTools.NodeRegister or {}

local logModuleName = "NodeRegister"

local nodeRegister = {}

function RPTools.NodeRegister.RegisterNode(node)
    local isvalid, error_message = RPTools.Node.ValidateNode(node)
    if not isvalid then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Tried to register an invalid node (" .. error_message .. ")")
        return
    end
    
    local id = RPTools.Node.GetId(node) or RPTools.Node.GenerateId(node)
    
    nodeRegister[id] = node
    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Added node with id:(" .. id .. ") to the node register.")
    -- Hook pour prévenir de l'ajout?
end

function RPTools.NodeRegister.UnregisterNode(id)
    if not nodeRegister[id] then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Trying to remove node: node (" .. table.ToString(node) .. ") not found")
        return
    end
    nodeRegister[id] = nil
    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Removed node with id:(" .. id .. ") from the node register.")
    -- Hook pour prévenir de la suppression?
end

function RPTools.NodeRegister.GetNodeById(id)
    local node = nodeRegister[id]
    if not node then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Trying to get node: node (" .. table.ToString(node) .. ") not found")
        return
    end
    
    return table.Copy(node)
end

function RPTools.NodeRegister.GetAllNodes()
    return table.ClearKeys(nodeRegister)
end

function RPTools.NodeRegister.EditNode(id, subNode)
    local node = RPTools.NodeRegister.GetNodeById(id)
    
    if not node then return end
    
    local errorMessage = RPTools.Node.Edit(node, subNode)
    
    if errorMessage then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Failed to edit node with id:(" .. id .. "): " .. errorMessage)
    end
    
    nodeRegister[id] = node
    
    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Edited node with id:(" .. id .. ")")
end

function RPTools.NodeRegister.ClearAll()
    nodeRegister = {}
end


RPTools.Network.RegisterClientHandler(RPTools.Network.MSG_TYPE.DELETE_NODE, function (ply)
    if not ply:IsAdmin() then return end
    
    local id = net.ReadString()

    RPTools.NodeRegister.UnregisterNode(id)
end)