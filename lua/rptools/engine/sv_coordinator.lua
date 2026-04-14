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

local nodePlayerState = {}

local function getOrCreatePlayerState(steamId, nodeId)
  nodePlayerState[steamId] = nodePlayerState[steamId] or {}
  nodePlayerState[steamId][nodeId] = nodePlayerState[steamId][nodeId]
    or {
      wasActivated = false,
      isActive = false,
      timer = 0,
      lastActivationTime = 0,
    }

  return nodePlayerState[steamId][nodeId]
end

---@param steamid string
---@return table
function RPTools.Coordinator.GetNodeState(steamid)
  return nodePlayerState[steamid] or {}
end

function RPTools.Coordinator.ClearAllState()
  nodePlayerState = {}
end

local function createEvaluationContext(ply, node)
  RPTools.Coordinator.SetNodeRunningState(node.id, RPTools.Coordinator.NODE_STATE.RUNNING)

  return {
    ply = ply,
    node = node,
    nodeId = node.id,
    state = getOrCreatePlayerState(ply:SteamID64(), node.id),
    filtered = false,
  }
end

local function createEvaluationContexts(plys, nodes)
  local evaluationContexts = {}
  for _, ply in ipairs(plys) do
    for _, node in ipairs(nodes) do
      table.insert(evaluationContexts, createEvaluationContext(ply, node))
    end
  end
  return evaluationContexts
end

local function filterByGlobalState(evaluationContext)
  local runningState = RPTools.Coordinator.GetNodeRunningState(evaluationContext.nodeId)
  if runningState == RPTools.Coordinator.NODE_STATE.RUNNING then
    return true
  elseif runningState == RPTools.Coordinator.NODE_STATE.PAUSED then
    return false
  elseif runningState == RPTools.Coordinator.NODE_STATE.ERROR then
    return false
  else
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Unknown running state for " .. evaluationContext.nodeId
    )
    return false
  end
end

local function filterByPolicy(evaluationContext, time)
  local policy = evaluationContext.node.triggerPolicy
  if policy == RPTools.Node.TRIGGER_POLICY.MANUAL then
    return false
  elseif policy == RPTools.Node.TRIGGER_POLICY.ONE_SHOT then
    return not evaluationContext.state.wasActivated
  elseif policy == RPTools.Node.TRIGGER_POLICY.COOLDOWN then
    return (time - evaluationContext.state.lastActivationTime) >= evaluationContext.node.cooldownDuration
  elseif policy == RPTools.Node.TRIGGER_POLICY.CONTINOUS then
    return true -- filtered later
  else
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Unknown trigger policy for " .. evaluationContext.nodeId
    )
    return false
  end
end

local function filter(evaluationContexts, time)
  for _, evaluationContext in ipairs(evaluationContexts) do
    if evaluationContext.filtered then
      continue
    end

    if not filterByGlobalState(evaluationContext) then
      evaluationContext.filtered = true
      continue
    end
    if not filterByPolicy(evaluationContext, time) then
      evaluationContext.filtered = true
      continue
    end
  end
end

local function evaluateConditions(evaluationContexts)
  for _, evaluationContext in ipairs(evaluationContexts) do
    if evaluationContext.filtered then
      continue
    end

    local contextSuccess, err = pcall(function()
      evaluationContext.conditionsMet = true

      for _, condition in pairs(evaluationContext.node.conditions) do
        local source = condition.source
        local sourceParam = condition.sourceParameter
        local operator = condition.operator
        local value = condition.value

        local sourceValue =
          RPTools.Sources.Server.GetFunction(source)(evaluationContext.ply, evaluationContext.node, sourceParam)

        local conditionResult = RPTools.Operators.GetFunction(operator)(sourceValue, value)

        if not conditionResult then
          evaluationContext.conditionsMet = false
          break
        end
      end
    end)

    if not contextSuccess then
      evaluationContext.filtered = true
      RPTools.Coordinator.SetNodeRunningState(evaluationContext.nodeId, RPTools.Coordinator.NODE_STATE.ERROR)
      RPTools.Logs.log(
        RPTools.Logs.LEVEL.ERROR,
        logModuleName,
        "Condition evaluation error on " .. evaluationContext.nodeId .. ": " .. err
      )
    end
  end
end

local function updateTimers(evaluationContexts, deltaTime)
  for _, evaluationContext in ipairs(evaluationContexts) do
    if evaluationContext.filtered then
      continue
    end

    evaluationContext.timerReached = false

    if evaluationContext.conditionsMet then
      evaluationContext.state.timer = evaluationContext.state.timer + deltaTime
      evaluationContext.timerReached = evaluationContext.state.timer >= evaluationContext.node.requiredTime
    else
      evaluationContext.state.timer = 0
    end
  end
end

local function prepare(evaluationContexts)
  for _, evaluationContext in ipairs(evaluationContexts) do
    if evaluationContext.filtered then
      continue
    end
    evaluationContext.actionsToExecute = {}
    evaluationContext.shouldActivate = false
    evaluationContext.shouldDeactivate = false
    if evaluationContext.conditionsMet and evaluationContext.timerReached then
      if
        evaluationContext.node.triggerPolicy == RPTools.Node.TRIGGER_POLICY.CONTINOUS
        and evaluationContext.state.isActive
      then
        continue
      end

      for _, action in ipairs(evaluationContext.node.actions) do
        table.insert(evaluationContext.actionsToExecute, action)
      end
      evaluationContext.shouldActivate = true
      RPTools.Logs.log(
        RPTools.Logs.LEVEL.INFO,
        logModuleName,
        "Node "
          .. evaluationContext.nodeId
          .. " will activate for "
          .. evaluationContext.ply:Nick()
          .. " ("
          .. #evaluationContext.actionsToExecute
          .. " actions)"
      )
    else
      if
        evaluationContext.node.triggerPolicy == RPTools.Node.TRIGGER_POLICY.CONTINOUS
        and evaluationContext.state.isActive
      then
        evaluationContext.shouldDeactivate = true
        RPTools.Logs.log(
          RPTools.Logs.LEVEL.INFO,
          logModuleName,
          "Node " .. evaluationContext.nodeId .. " will deactivate for " .. evaluationContext.ply:Nick()
        )
      end
    end
  end
end

local function execute(evaluationContexts, time)
  for _, evaluationContext in ipairs(evaluationContexts) do
    if evaluationContext.filtered then
      continue
    end
    if evaluationContext.shouldDeactivate then
      evaluationContext.state.isActive = false
      hook.Run("RPTools_NodeDeactivated", evaluationContext.ply, table.Copy(evaluationContext.node))
    end
    if not evaluationContext.shouldActivate then
      continue
    end
    evaluationContext.state.wasActivated = true
    evaluationContext.state.isActive = true
    evaluationContext.state.lastActivationTime = time
    evaluationContext.state.timer = 0
    local executionSuccess, error = pcall(function()
      for _, action in ipairs(evaluationContext.actionsToExecute) do
        local params = RPTools.Actions.Server.GetParams(action)
        RPTools.Actions.Server.GetFunction(RPTools.Actions.Server.GetActionType(action))(
          evaluationContext.ply,
          evaluationContext.node,
          params
        )
      end
    end)

    if not executionSuccess then
      evaluationContext.filtered = true
      RPTools.Coordinator.SetNodeRunningState(evaluationContext.nodeId, RPTools.Coordinator.NODE_STATE.ERROR)
      RPTools.Logs.log(
        RPTools.Logs.LEVEL.ERROR,
        logModuleName,
        "Execution error on " .. evaluationContext.nodeId .. ": " .. tostring(error)
      )
    else
      RPTools.Logs.log(
        RPTools.Logs.LEVEL.INFO,
        logModuleName,
        "Node "
          .. evaluationContext.nodeId
          .. " activated for "
          .. evaluationContext.ply:Nick()
          .. ", "
          .. #evaluationContext.actionsToExecute
          .. " actions executed"
      )

      hook.Run(
        "RPTools_NodeActivated",
        evaluationContext.ply,
        table.Copy(evaluationContext.node),
        table.Copy(evaluationContext.actionsToExecute)
      )
    end
  end
end

local lastTime = CurTime()

local function mainLoop()
  local time = CurTime()
  local deltaTime = time - lastTime
  lastTime = time

  local nodes = RPTools.NodeRegister.GetAllNodes()
  local plys = {}
  for _, ply in player.Iterator() do
    if not ply:IsAdmin() or not ply:GetNW2Bool("rptools_vanish", false) then
      table.insert(plys, ply)
    end
  end

  local evaluationContexts = createEvaluationContexts(plys, nodes)

  filter(evaluationContexts, time)
  evaluateConditions(evaluationContexts)
  updateTimers(evaluationContexts, deltaTime)
  prepare(evaluationContexts)
  execute(evaluationContexts, time)
end

function RPTools.Coordinator.Start()
  timer.Create("RPTools_Coordinator", 0.1, 0, mainLoop)
end

function RPTools.Coordinator.Stop()
  timer.Stop("RPTools_Coordinator")
end
