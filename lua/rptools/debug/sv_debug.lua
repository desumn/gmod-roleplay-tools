RPTools = RPTools or {}
RPTools.Debug = RPTools.Debug or {}

local debugMode = {}

---@param node RPToolsNode
function RPTools.Debug.WriteDebugNode(node)
  local id = RPTools.Node.GetId(node)
  local anchor = table.Copy(node.anchor)
  if anchor.type == "entity" then
    local ent = RPTools.Entities.Get(anchor.entityId)
    anchor.entityId = (ent and ent:EntIndex()) or nil
  end
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
  net.WriteTable(anchor)
  net.WriteUInt((table.IsEmpty(distances) and 0) or math.max(unpack(distances)), 16)
  net.WriteUInt(state or 1, 3)
  net.WriteTable(conditionsDesc, true)
  net.WriteTable(actionsDesc, true)
end

local function getDebugPlayers()
  local targets = {}
  for _, ply in player.Iterator() do
    if ply:GetNW2Bool("rptools_debug", false) then
      table.insert(targets, ply)
    end
  end
  return targets
end

hook.Add("RPTools_NodeCreated", "RPTools_DebugNodeCreate", function(id, node)
  RPTools.Network.SendToClients(getDebugPlayers(), RPTools.Network.MSG_TYPE.DEBUG_ADD, function()
    net.WriteBool(false)
    net.WriteUInt(1, 12)
    RPTools.Debug.WriteDebugNode(node)
  end)
end)

hook.Add("RPTools_NodeRemoved", "RPTools_DebugNodeRemove", function(id)
  RPTools.Network.SendToClients(getDebugPlayers(), RPTools.Network.MSG_TYPE.DEBUG_REMOVE, function()
    net.WriteString(id)
  end)
end)

local function sendAllNodes(target)
  local nodes = RPTools.NodeRegister.GetAllNodes()
  if #nodes == 0 then
    return
  end

  RPTools.Network.SendToClients(target, RPTools.Network.MSG_TYPE.DEBUG_ADD, function()
    net.WriteBool(true)
    net.WriteUInt(#nodes, 12)
    for _, node in ipairs(nodes) do
      RPTools.Debug.WriteDebugNode(node)
    end
  end)
end

RPTools.Network.OnClientMessage(RPTools.Network.MSG_TYPE.DEBUG_TOGGLE, function(ply)
  if not ply:IsAdmin() then
    return
  end
  ply:SetNW2Bool("rptools_debug", not ply:GetNW2Bool("rptools_debug", false))
  if ply:GetNW2Bool("rptools_debug", false) then
    sendAllNodes(ply)
  end
end)
