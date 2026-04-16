RPTools = RPTools or {}

RPTools.Coordinator = RPTools.Coordinator or {}

local logModuleName = "Coordinator"

local nodeState = {}

---@param nodeId string
---@return RPToolsNodeState|nil
function RPTools.Coordinator.GetNodeRunningState(nodeId)
  return nodeState and nodeState[nodeId]
end

---@param nodeId string
---@param state RPToolsNodeState
function RPTools.Coordinator.SetNodeRunningState(nodeId, state)
  local oldState = nodeState[nodeId]
  nodeState[nodeId] = state
  hook.Run("RPTools_NodeStateChanged", nodeId, state, oldState)
end

local activeNodes = {}

local function countActivePlayers(nodeId)
  return table.Count(activeNodes[nodeId])
end

local candidates = {}

local lastTime = CurTime()

local function isRunning(node)
  return RPTools.Coordinator.GetNodeRunningState(node.id) == RPTools.Coordinator.NODE_STATE.RUNNING
end

hook.Add("RPTools_NodeCreated", "rptools_coordinator_initial_state", function(id, node)
  RPTools.Coordinator.SetNodeRunningState(id, RPTools.Coordinator.NODE_STATE.RUNNING)
  candidates[id] = {}
end)

hook.Add("RPTools_NodeRemoved", "rptools_coordinator_clean_node_state", function(id)
  RPTools.Coordinator.SetNodeRunningState(id, nil)
  activeNodes[id] = nil
  candidates[id] = nil
end)

hook.Add("PlayerDisconnected", "rptools_coordinator_clean_player_state", function(ply)
  for id, state in pairs(activeNodes) do
    if not state[ply:SteamID64()] then continue end
    state[ply:SteamID64()] = nil
    if countActivePlayers(id) == 0 then
      hook.Run("RPTools_NodeDeactivated", id, RPTools.NodeRegister.GetNodeById(id))
    else
      hook.Run("RPTools_PlayersDeactivations", id, RPTools.NodeRegister.GetNodeById(id), { ply })
    end
  end
  for id, state in pairs(candidates) do
    state[ply:SteamID64()] = nil
  end
end)

hook.Add("RPTools_ZoneEntered", "rptools_coordinator_zone_enter", function(id, ply)
  candidates[id][ply:SteamID64()] = true
end)

hook.Add("RPTools_ZoneExited", "rptools_coordinator_zone_exit", function(id, ply)
  if not candidates[id] then
    return
  end
  candidates[id][ply:SteamID64()] = nil
  if not activeNodes[id] then
    return
  end
  if not activeNodes[id][ply:SteamID64()] then
    return
  end
  activeNodes[id][ply:SteamID64()] = nil
  if countActivePlayers(id) == 0 then
    hook.Run("RPTools_NodeDeactivated", id, RPTools.NodeRegister.GetNodeById(id))
  else
    hook.Run("RPTools_PlayersDeactivations", id, RPTools.NodeRegister.GetNodeById(id), { ply })
  end
end)

local function evaluateConditions(node, ply)
  local conditionsMet = true
  for _, condition in ipairs(node.conditions) do
    local source = condition.source
    local param = condition.sourceParameter
    local operator = condition.operator
    
    if source == "distance" and (operator == "lt" or operator == "le") then
      continue
    end
    
    local value = condition.value
    local sourceValue = RPTools.Sources.Server.GetFunction(source)(ply, node, param)
    
    if not RPTools.Operators.GetFunction(operator)(sourceValue, value) then
      conditionsMet = false
      break
    end
  end
  return conditionsMet
end

local function mainLoop()
  local time = CurTime()
  local deltaTime = time - lastTime
  lastTime = time
  
  local nodes = RPTools.NodeRegister.GetAllNodes()
  ---@type RPToolsNode[]
  local runningNodes = {}
  for _, node in ipairs(nodes) do
    if isRunning(node) then
      table.insert(runningNodes, node)
    end
  end
  
  local plys = {}
  for _, ply in player.Iterator() do
    if not ply:IsAdmin() or not ply:GetNW2Bool("rptools_vanish", false) then
      table.insert(plys, ply)
    end
  end
  
  for _, node in ipairs(runningNodes) do
    local activations = {}
    local deactivations = {}
    activeNodes[node.id] = activeNodes[node.id] or {}
    local oldActivePlayers = countActivePlayers(node.id)
    for _, ply in ipairs(plys) do
      if not candidates[node.id][ply:SteamID64()] then
        continue
      end
      
      local conditionSuccess, conditionsMet = pcall(evaluateConditions, node, ply)
      
      if not conditionSuccess then
        RPTools.Coordinator.SetNodeRunningState(node.id, RPTools.Coordinator.NODE_STATE.ERROR)
        RPTools.Logs.log(
        RPTools.Logs.LEVEL.ERROR,
        logModuleName,
        node.id .. " condition evaluation failed: " .. conditionsMet
      )
      continue
    end
    
    if not conditionsMet then
      if activeNodes[node.id][ply:SteamID64()] then
        table.insert(deactivations, ply)
      end
      activeNodes[node.id][ply:SteamID64()] = nil
      continue
    end
    
    if activeNodes[node.id][ply:SteamID64()] then
      continue
    end
    
    activeNodes[node.id][ply:SteamID64()] = true
    
    table.insert(activations, ply)
  end
  
  local newActivePlayers = countActivePlayers(node.id)
  
  if oldActivePlayers == 0 and newActivePlayers > 0 then
    hook.Run("RPTools_NodeActivated", node.id, node, activations)
  end
  if oldActivePlayers > 0 and newActivePlayers == 0 then
    hook.Run("RPTools_NodeDeactivated", node.id, node)
  end
  if oldActivePlayers > 0 and #activations > 0 then
    hook.Run("RPTools_PlayersActivation", node.id, node, activations)
  end
  if newActivePlayers > 0 and #deactivations > 0 then
    hook.Run("RPTools_PlayersDeactivations", node.id, node, deactivations)
  end
end
end

function RPTools.Coordinator.Start()
  timer.Create("RPTools_Coordinator", 0.1, 0, mainLoop)
  hook.Run("RPTools_CoordinatorStarted")
end

function RPTools.Coordinator.Stop()
  timer.Remove("RPTools_Coordinator")
  hook.Run("RPTools_CoordinatorStopped")
end
