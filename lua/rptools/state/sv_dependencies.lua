RPTools = RPTools or {}
RPTools.Dependencies = RPTools.Dependencies or {}

local dependencyGraph = {}

local nodeIO = {}

local trackedInputs = {
  flag = RPTools.Blackboard.Key.Flag,
  counter = RPTools.Blackboard.Key.Counter,
}

local trackedOutputs = {
  flag = RPTools.Blackboard.Key.Flag,
  increment = RPTools.Blackboard.Key.Counter,
}

---@param node RPToolsNode
local function extractInputs(node)
  local inputs = {}
  for _, condition in ipairs(node.conditions) do
    local tracked = trackedInputs[condition.source]
    if tracked then
      local parameter = condition.sourceParameter
      table.insert(inputs, tracked(parameter))
    end
  end
  return inputs
end

---@param node RPToolsNode
local function extractOutputs(node)
  local outputs = {}
  for _, action in ipairs(node.actions) do
    local tracked = trackedOutputs[action.actionType]
    if tracked then
      local parameter = action.params.key
      table.insert(outputs, tracked(parameter))
    end
  end
  return outputs
end

local function getOrCreate(key)
  local ressources = dependencyGraph[key]
  if ressources == nil then
    dependencyGraph[key] = {
      consumers = {},
      producers = {},
    }
    ressources = dependencyGraph[key]
  end
  return ressources
end

hook.Add("RPTools_NodeCreated", "RPTools_AddDependency", function(id, node)
  local inputs = extractInputs(node)
  local outputs = extractOutputs(node)

  nodeIO[id] = { inputs = inputs, outputs = outputs }

  for _, input in ipairs(inputs) do
    local ressources = getOrCreate(input)
    ressources.consumers[id] = true
  end

  for _, output in ipairs(outputs) do
    local ressources = getOrCreate(output)
    ressources.producers[id] = true
  end
end)

hook.Add("RPTools_NodeRemoved", "RPTools_RemoveDependency", function(id)
  if nodeIO[id] == nil then
    return
  end
  local inputs = nodeIO[id].inputs
  local outputs = nodeIO[id].outputs

  if not table.IsEmpty(inputs) then
    for _, input in ipairs(inputs) do
      local ressources = dependencyGraph[input]
      if ressources == nil then
        continue
      end
      ressources.consumers[id] = nil
      if table.IsEmpty(ressources.consumers) and table.IsEmpty(ressources.producers) then
        dependencyGraph[input] = nil
      end
    end
  end

  if not table.IsEmpty(outputs) then
    for _, output in ipairs(outputs) do
      local ressources = dependencyGraph[output]
      if ressources == nil then
        continue
      end
      ressources.producers[id] = nil
      if table.IsEmpty(ressources.consumers) and table.IsEmpty(ressources.producers) then
        dependencyGraph[output] = nil
      end
    end
  end

  nodeIO[id] = nil
end)

function RPTools.Dependencies.ListRessourceKeys(keyType)
  local keys = {}
  for key, _ in pairs(dependencyGraph) do
    if RPTools.Blackboard.ExtractKeyType(key) == keyType then
      local name = RPTools.Blackboard.ExtractName(key, keyType)
      table.insert(keys, name)
    end
  end
  return keys
end

concommand.Add("debug_depgraph", function(ply, cmd, args, argStr)
  print("Graph: ")
  PrintTable(dependencyGraph)
  print("IOs: ")
  PrintTable(nodeIO)
end)

concommand.Add("debug_listkeys", function(ply, cmd, args, argStr)
  print("keys: ")
  PrintTable(RPTools.Dependencies.ListRessourceKeys(RPTools.Blackboard.Key.Flag()))
  print("counters: ")
  PrintTable(RPTools.Dependencies.ListRessourceKeys(RPTools.Blackboard.Key.Counter()))
end)
