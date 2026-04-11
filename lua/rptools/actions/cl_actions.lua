RPTools = RPTools or {}
RPTools.Actions = RPTools.Actions or {}
RPTools.Actions.Client = RPTools.Actions.Client or {}

local logModuleName = "Action:Client"

local clientFunctions = {}

function RPTools.Actions.Client.RegisterAction(name, func)
    clientFunctions[name] = func
end

RPTools.Network.OnServerMessage(RPTools.Network.MSG_TYPE.CLIENT_ACTION, function ()
    local name = net.ReadString()
    local params = net.ReadTable()

    local func = clientFunctions[name]

    if not func or not isfunction(func) then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Invalid client action: " .. name)
        return
    end

    local success, error = pcall(func, params)

    if success then
        return
    else
        RPTools.Logs.log(RPTools.Logs.LEVEL.ERROR, logModuleName, "Action " .. name .. " crashed: " .. error)
    end
end)