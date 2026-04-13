RPTools = RPTools or {}
RPTools.Serialization = RPTools.Serialization or {}
RPTools.Save = RPTools.Save or {}

local function preSerializeNodes()
  local nodes = table.Copy(RPTools.NodeRegister.GetAllNodes())
  for _, node in ipairs(nodes) do
    node.id = nil
  end
  return nodes
end

local function postSerializeNodes(nodes)
  return nodes
end

local function preSerializeBlackboard()
  local blackboard = RPTools.Blackboard.GetAll()
  local serializedBlackboard = {}
  for steamid, data in pairs(blackboard) do
    serializedBlackboard[":" .. steamid] = data
  end
  return serializedBlackboard
end

local function postSerializeBlackboard(newBlackboard)
  if not newBlackboard then
    return nil
  end

  local deserializedBlackboard = {}

  for steamid, data in pairs(newBlackboard) do
    deserializedBlackboard[string.TrimLeft(steamid, ":")] = data
  end

  return deserializedBlackboard
end

---@param name string
function RPTools.Save.SaveAll(name)
  local save = {
    version = 0,
    nodes = preSerializeNodes(),
    blackboard = preSerializeBlackboard(),
  }

  local text = util.TableToJSON(save, true)

  file.CreateDir("rptools/saves")
  file.Write("rptools/saves/" .. name .. ".json", text)
  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, "Save", "Wrote save " .. name .. " to the disk.")
  hook.Run("RPTools_SaveCompleted", name)
end

---@param name string
---@return boolean
function RPTools.Save.LoadAll(name)
  if not file.Exists("rptools/saves/" .. name .. ".json", "DATA") then
    return false
  end
  local json = file.Read("rptools/saves/" .. name .. ".json")

  local save = util.JSONToTable(json)
  if not save then
    return false
  end

  -- No migration mechanism, will be added once there's a migration to do

  if not save.blackboard then
    return false
  end
  local blackboard = postSerializeBlackboard(save.blackboard)
  if not blackboard then
    return false
  end

  RPTools.Blackboard.Merge(blackboard)

  if not save.nodes then
    return false
  end
  local nodes = postSerializeNodes(save.nodes)

  if not nodes then
    return false
  end

  for _, node in ipairs(nodes) do
    RPTools.NodeRegister.RegisterNode(node)
  end

  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, "Save", "Loaded save " .. name .. " from the disk.")

  hook.Run("RPTools_LoadCompleted", name)

  return true
end

---@return string[]
function RPTools.Save.ListSaves()
  local files = file.Find("rptools/saves/*", "DATA")
  return files
end

---@param name string
---@return boolean
function RPTools.Save.Delete(name)
  if not file.Exists("rptools/saves/" .. name .. ".json", "DATA") then
    return false
  end

  file.Delete("rptools/saves/" .. name .. ".json", "DATA")
  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, "Save", "Removed save " .. name .. " from the disk.")

  return true
end
