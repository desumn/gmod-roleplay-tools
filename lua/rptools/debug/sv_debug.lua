RPTools = RPTools or {}
RPTools.Debug = RPTools.Debug or {}

local debugMode = false

function RPTools.Debug.WriteDebugNode(node)
  local id = RPTools.Node.GetId(node)
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

  net.WriteString(id)
  net.WriteVector(position)
  net.WriteUInt((table.IsEmpty(distances) and 0) or math.max(unpack(distances)), 16)
  net.WriteUInt(state or 1, 3)
end

local function sendAllNodes()
  local nodes = RPTools.NodeRegister.GetAllNodes()
  if #nodes == 0 then
    return
  end
  RPTools.Network.SendToAdmins(RPTools.Network.MSG_TYPE.DEBUG_SYNC, function()
    net.WriteUInt(#nodes, 12)
    for _, node in ipairs(nodes) do
      RPTools.Debug.WriteDebugNode(node)
    end
  end)
end

local function enableDebug()
  debugMode = true
  timer.Create("rptools_debugMode", 1, 0, function()
    sendAllNodes()
  end)
end

local function disableDebug()
  debugMode = false
  timer.Remove("rptools_debugMode")
end

RPTools.Network.OnClientMessage(RPTools.Network.MSG_TYPE.DEBUG_TOGGLE, function(ply)
  if not ply:IsAdmin() then
    return
  end
  if debugMode then
    disableDebug()
  else
    enableDebug()
  end
end)
