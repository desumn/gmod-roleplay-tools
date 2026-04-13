RPTools = RPTools or {}
RPTools.Debug = RPTools.Debug or {}

local debugMode = {}

---@param node RPToolsNode
function RPTools.Debug.WriteDebugNode(node)
  local id = RPTools.Node.GetId(node)
  local policy = RPTools.Node.GetTriggerPolicy(node)
  local policyText = RPTools.Node.FormatPolicy(policy)
  local position = RPTools.Node.GetPosition(node)

  local conditions = RPTools.Node.GetConditions(node)

  local distances = {}
  for _, condition in ipairs(conditions) do
    local source = RPTools.Condition.GetSource(condition)
    if source ~= "distance" then
      continue
    end
    local operator = RPTools.Condition.GetOperator(condition)
    if operator ~= "le" and operator ~= "lt" then
      continue
    end

    table.insert(distances, RPTools.Condition.GetValue(condition))
  end

  local state = RPTools.Coordinator.GetNodeRunningState(id)

  local conditionsDesc = {}
  for _, condition in ipairs(node.conditions) do
    local formattedSource = RPTools.Sources.Server.GetFormatter(condition.source)(condition.sourceParameter)
    local formattedCondition = RPTools.Operators.GetFormatter(condition.operator)(formattedSource, condition.value)
    table.insert(conditionsDesc, formattedCondition)
  end

  local actionsDesc = {}
  for _, action in ipairs(node.actions) do
    table.insert(actionsDesc, RPTools.Actions.Server.GetFormatter(action.actionType)(action.params))
  end

  net.WriteString(id)
  net.WriteUInt(policy, 3)
  net.WriteString(policyText)
  net.WriteVector(position)
  net.WriteUInt((table.IsEmpty(distances) and 0) or math.max(unpack(distances)), 16)
  net.WriteUInt(state or 1, 3)
  net.WriteTable(conditionsDesc, true)
  net.WriteTable(actionsDesc, true)
end

hook.Add("RPTools_NodeCreated", "RPTools_DebugNodeCreate", function(id, node)
  local targets = {}
  for _, ply in pairs(debugMode) do
    table.insert(targets, ply)
  end
  RPTools.Network.SendToClients(targets, RPTools.Network.MSG_TYPE.DEBUG_ADD, function()
    net.WriteUInt(1, 12)
    RPTools.Debug.WriteDebugNode(node)
  end)
end)

hook.Add("RPTools_NodeRemoved", "RPTools_DebugNodeRemove", function(id)
  local targets = {}
  for _, ply in pairs(debugMode) do
    table.insert(targets, ply)
  end
  RPTools.Network.SendToClients(targets, RPTools.Network.MSG_TYPE.DEBUG_REMOVE, function()
    net.WriteString(id)
  end)
end)

local function sendAllNodes(target)
  local nodes = RPTools.NodeRegister.GetAllNodes()
  if #nodes == 0 then
    return
  end

  RPTools.Network.SendToClients(target, RPTools.Network.MSG_TYPE.DEBUG_ADD, function()
    net.WriteUInt(#nodes, 12)
    for _, node in ipairs(nodes) do
      RPTools.Debug.WriteDebugNode(node)
    end
  end)
end

local function enableDebug(ply)
  debugMode[ply:SteamID64()] = ply
end

local function disableDebug(ply)
  debugMode[ply:SteamID64()] = nil
end

RPTools.Network.OnClientMessage(RPTools.Network.MSG_TYPE.DEBUG_TOGGLE, function(ply)
  if not ply:IsAdmin() then
    return
  end
  if debugMode[ply:SteamID64()] then
    disableDebug(ply)
  else
    enableDebug(ply)
    sendAllNodes(ply)
  end
end)
