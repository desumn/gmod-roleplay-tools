RPTools = RPTools or {}

RPTools.Utilities = RPTools.Utilities or {}

---@param n any
---@return boolean
function RPTools.Utilities.IsNumber(n)
  return isnumber(n) and n == n and n ~= math.huge
end

---@param result any
---@param message string
---@return boolean, string
function RPTools.Utilities.MakeError(result, message)
  if not result then
    return false, message
  else
    return true, ""
  end
end

---@param table table
---@param cond fun(value: any): boolean
---@return boolean
function RPTools.Utilities.AllValues(table, cond)
  for _, value in pairs(table) do
    if not cond(value) then
      return false
    end
  end
  return true
end

---@param table table
---@param cond fun(key: any): boolean
---@return boolean
function RPTools.Utilities.AllKeys(table, cond)
  for key, _ in pairs(table) do
    if not cond(key) then
      return false
    end
  end
  return true
end

---@param table any
---@return boolean
function RPTools.Utilities.IsSet(table, cond)
  return istable(table) and RPTools.Utilities.AllValues(table, function(val)
    return isbool(val) and val
  end)
end

---@param name string
---@return Player[]
function RPTools.Utilities.FindPlayerByName(name)
  local players = {}

  for _, ply in ipairs(player.GetAll()) do
    if string.find(string.lower(ply:Nick()), name) then
      table.insert(players, ply)
    end
  end

  return players
end

---@param table table
---@param f fun(key: any, value: any): any
---@return table
function RPTools.Utilities.Map(table, f)
  local returnTable = {}

  for k, v in pairs(table) do
    returnTable[k] = f(k, v)
  end
  return returnTable
end
