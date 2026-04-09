RPTools = RPTools or {}
RPTools.Serialization = RPTools.Serialization or {}
RPTools.Save = RPTools.Save or {}

local function serializeNodes()
  local nodes = table.Copy(RPTools.NodeRegister.GetAllNodes())
  for _, node in ipairs(nodes) do
    node.id = nil
  end
  return util.TableToJSON(nodes, true)
end

local function deserializeNodes(json)
  return util.JSONToTable(json)
end

local function serializeBlackboard()
  local blackboard = RPTools.Blackboard.GetAll()
  local serializedBlackboard = {}
  for steamid, data in pairs(blackboard) do
    serializedBlackboard[":" .. steamid] = data
  end
  return util.TableToJSON(serializedBlackboard)
end

local function deserializeBlackboard(blackboard_json)
  local newBlackboard = util.JSONToTable(blackboard_json)
  if not newBlackboard then
    return nil
  end

  for steamid, data in pairs(newBlackboard) do
    newBlackboard[string.TrimLeft(steamid, ":")] = data
  end

  return newBlackboard
end

---@param name string
function RPTools.Save.SaveAll(name)
  local save = {
    version = 0,
    nodes = serializeNodes(),
    blackboard = serializeBlackboard(),
  }

  local text = util.TableToJSON(save)

  file.CreateDir("rptools/saves")
  file.Write("rptools/saves/" .. name .. ".json", text)
  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, "Save", "Wrote save " .. name .. " to the disk.")
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
  local blackboard = deserializeBlackboard(save.blackboard)
  if not blackboard then
    return false
  end

  RPTools.Blackboard.Merge(blackboard)

  if not save.nodes then
    return false
  end
  local nodes = deserializeNodes(save.nodes)

  if not nodes then
    return false
  end

  for _, node in ipairs(nodes) do
    RPTools.NodeRegister.RegisterNode(node)
  end

  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, "Save", "Loaded save " .. name .. " from the disk.")

  return true
end

---@return string[]
function RPTools.Save.ListSave()
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
