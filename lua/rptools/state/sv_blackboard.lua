RPTools = RPTools or {}

local logModuleName = "Blackboard"

RPTools.Blackboard = RPTools.Blackboard or {}

local blackboard = {}

---@param ply Player
---@param key string
---@return any
function RPTools.Blackboard.Read(ply, key)
  if not ply or not ply:IsValid() then
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Tried to read in blackboard on invalid player: " .. tostring(ply) .. " with key: " .. tostring(key)
    )
    return
  end

  if not isstring(key) then
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Tried to read non string key: " .. tostring(key) .. " for player " .. tostring(ply:Nick())
    )
    return
  end

  local steamid = ply:SteamID64()

  blackboard[steamid] = blackboard[steamid] or {}
  return blackboard[steamid][key]
end

---@param ply Player
---@param key string
---@param value any
function RPTools.Blackboard.Write(ply, key, value)
  if not ply or not ply:IsValid() then
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Tried to write in blackboard on invalid player: " .. tostring(ply) .. " with key: " .. tostring(key)
    )
    return
  end

  if not isstring(key) then
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Tried to write non string key: "
        .. tostring(key)
        .. " for player "
        .. tostring(ply:Nick())
        .. " with value: "
        .. tostring(value)
    )
    return
  end

  local steamid = ply:SteamID64()

  RPTools.Logs.log(
    RPTools.Logs.LEVEL.INFO,
    logModuleName,
    "Set (" .. key .. ", " .. tostring(value) .. ") in blackboard  for player " .. tostring(ply:Nick())
  )

  blackboard[steamid] = blackboard[steamid] or {}
  blackboard[steamid][key] = value
end

---@param ply Player
---@param key string
---@param value? number
function RPTools.Blackboard.Increment(ply, key, value)
  local incrementValue = value or 1

  if not ply or not ply:IsValid() then
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Tried to increment value in blackboard on invalid player: " .. tostring(ply) .. " with key: " .. tostring(key)
    )
    return
  end

  if not isstring(key) then
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Tried to increment non string key: "
        .. tostring(key)
        .. " for player "
        .. tostring(ply:Nick())
        .. " with increment value: "
        .. tostring(incrementValue)
    )
    return
  end

  local steamid = ply:SteamID64()

  blackboard[steamid] = blackboard[steamid] or {}
  local oldValue = blackboard[steamid][key] or 0

  RPTools.Logs.log(
    RPTools.Logs.LEVEL.INFO,
    logModuleName,
    "Incremented value at key "
      .. key
      .. " from "
      .. tostring(oldValue)
      .. " by "
      .. tostring(incrementValue)
      .. "in blackboard  for player "
      .. tostring(ply:Nick())
  )

  blackboard[steamid][key] = oldValue + incrementValue
end

---@param ply Player
function RPTools.Blackboard.ClearForPlayer(ply)
  if not ply or not ply:IsValid() then
    RPTools.Logs.log(
      RPTools.Logs.LEVEL.WARNING,
      logModuleName,
      "Tried to clear blackboard on invalid player: " .. tostring(ply)
    )
    return
  end
  local steamid = ply:SteamID64()

  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Cleared blackboard for player: " .. tostring(ply:Nick()))
  blackboard[steamid] = {}
end

---@return table
function RPTools.Blackboard.GetAll()
  return table.Copy(blackboard)
end

---@return string
function RPTools.Blackboard.ClearAll()
  RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Cleared all blackboard")
  blackboard = {}
end

---@param otherBlackboard table
function RPTools.Blackboard.Merge(otherBlackboard)
    table.Merge(blackboard, otherBlackboard)
end