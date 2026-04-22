RPTools = RPTools or {}

---@class RPToolsKeyMetadata
---@field scope RPToolsStateScope
---@field key string
---@field type integer
---@field firstSetAt number
---@field lastSetAt number
---@field writeCount number

---@class RPToolsGlobalKeyData
---@field value any
---@field metadata RPToolsKeyMetadata

---@class RPToolsPlayerKeyData
---@field values table<SteamID64, any>
---@field metadata RPToolsKeyMetadata

local stateTable = {
  ---@type table<string, RPToolsGlobalKeyData>
  global = {},
  ---@type table<string, RPToolsPlayerKeyData>
  players = {},
}

---@return RPToolsKeyMetadata[]
local function getSchema()
  local schema = {}
  for _, globals in pairs(stateTable.global) do
    table.insert(schema, globals.metadata)
  end
  for _, players in pairs(stateTable.players) do
    table.insert(schema, players.metadata)
  end
  return schema
end

local SCOPE = RPTools.State.Shared.SCOPE

---@param scope RPToolsStateScope
---@param key string
---@param context? Player
---@return any, string?
local function get(scope, key, context)
  if scope == SCOPE.GLOBAL then
    if not stateTable.global[key] then
      return nil, "No value for key " .. key
    end
    return stateTable.global[key].value
  elseif scope == SCOPE.PLAYER then
    if not IsValid(context) then
      return nil, "Invalid player"
    end
    if not stateTable.players[key] then
      return nil, "No value for key " .. key
    end
    return stateTable.players[key].values[context:SteamID64()] or nil
  end
  return nil, "Invalid scope"
end

---@param scope RPToolsStateScope
---@param key string
---@param ply? Player
---@return boolean?
local function getBoolean(scope, key, ply)
  local value = get(scope, key, ply)
  if TypeID(value) ~= TYPE_BOOL then
    return nil
  end
  return value
end

---@param scope RPToolsStateScope
---@param key string
---@param ply? Player
---@return number?
local function getNumber(scope, key, ply)
  local value = get(scope, key, ply)
  if TypeID(value) ~= TYPE_NUMBER then
    return nil
  end
  return value
end

---@param scope RPToolsStateScope
---@param key string
---@param ply? Player
---@return string?
local function getString(scope, key, ply)
  local value = get(scope, key, ply)
  if TypeID(value) ~= TYPE_STRING then
    return nil
  end
  return value
end

---@param scope RPToolsStateScope
---@param key string
---@param context? Player
---@return boolean, string?
local function remove(scope, key, context)
  if scope == SCOPE.GLOBAL then
    local oldValue = stateTable.global[key] and stateTable.global[key].value
    stateTable.global[key] = nil
    hook.Run("RPTools_StateValueChanged", scope, key, context, oldValue, nil)
    return true
  elseif scope == SCOPE.PLAYER then
    if not IsValid(context) then
      return false, "Invalid player"
    end
    if stateTable.players[key] then
      local oldValue = stateTable.players[key].values[context:SteamID64()]
      stateTable.players[key].values[context:SteamID64()] = nil
      hook.Run("RPTools_StateValueChanged", scope, key, context, oldValue, nil)
    end
    return true
  end
  return false, "Invalid scope"
end

local function createTimer(duration, scope, key, context)
  if duration ~= nil and duration > 0 then
    local steamID = (context and context:SteamID64()) or ""
    timer.Create(
      "rptools_" .. tostring(scope) .. "_" .. key .. tostring(steamID) .. "_autoremove",
      duration,
      1,
      function()
        remove(scope, key, context)
      end
    )
  end
end

---@generic T
---@param scope RPToolsStateScope
---@param key string
---@param value T
---@param context? Player
---@param duration? number
---@return boolean, string?
local function set(scope, key, value, context, duration)
  local valueType = TypeID(value)
  if scope == SCOPE.GLOBAL then
    local oldValue = stateTable.global[key] and stateTable.global[key].value
    ---@type RPToolsGlobalKeyData
    stateTable.global[key] = stateTable.global[key]
      or {
        metadata = {
          scope = SCOPE.GLOBAL,
          key = key,
          type = valueType,
          firstSetAt = os.time(),
          lastSetAt = os.time(),
          writeCount = 0,
        },
      }
    if valueType == stateTable.global[key].metadata.type then
      stateTable.global[key].value = value
      stateTable.global[key].metadata.lastSetAt = os.time()
      stateTable.global[key].metadata.writeCount = stateTable.global[key].metadata.writeCount + 1
      hook.Run("RPTools_StateValueChanged", scope, key, context, oldValue, value)
      createTimer(duration, scope, key, context)
      return true
    else
      return false, "Invalid type for value"
    end
  elseif scope == SCOPE.PLAYER then
    if not IsValid(context) then
      return false, "Invalid player"
    end

    ---@type RPToolsPlayerKeyData
    stateTable.players[key] = stateTable.players[key]
      or {
        metadata = {
          scope = SCOPE.PLAYER,
          key = key,
          type = valueType,
          firstSetAt = os.time(),
          lastSetAt = os.time(),
          writeCount = 0,
        },
        values = {},
      }

    if valueType == stateTable.players[key].metadata.type then
      local oldValue = stateTable.players[key].values[context:SteamID64()]
      stateTable.players[key].metadata.lastSetAt = os.time()
      stateTable.players[key].metadata.writeCount = stateTable.players[key].metadata.writeCount + 1
      stateTable.players[key].values[context:SteamID64()] = value
      hook.Run("RPTools_StateValueChanged", scope, key, context, oldValue, value)
      createTimer(duration, scope, key, context)
      return true
    else
      return false, "Invalid type for value"
    end
  end
  return false, "Invalid scope"
end

---@param name string
---@param callback fun(scope: RPToolsStateScope, key:string, context:Player?, oldValue: any, newValue: any)
local function onChange(name, callback)
  hook.Add("RPTools_StateValueChanged", name, callback)
end

RPTools.State.Server = {
  GetSchema = getSchema,
  Get = get,
  GetBoolean = getBoolean,
  GetNumber = getNumber,
  GetString = getString,
  Set = set,
  Remove = remove,
  OnValueChange = onChange,
}

local TYPE_NAMES = {
  [TYPE_NIL] = "nil",
  [TYPE_BOOL] = "boolean",
  [TYPE_NUMBER] = "number",
  [TYPE_STRING] = "string",
  [TYPE_TABLE] = "table",
  [TYPE_FUNCTION] = "function",
  [TYPE_VECTOR] = "vector",
  [TYPE_ANGLE] = "angle",
  [TYPE_ENTITY] = "entity",
  [TYPE_COLOR] = "color",
  [TYPE_MATERIAL] = "material",
  [TYPE_SOUND] = "sound",
  [TYPE_USERDATA] = "userdata",
  [TYPE_PANEL] = "panel",
  [TYPE_CONVAR] = "convar",
  [TYPE_PARTICLE] = "particle",
  [TYPE_PARTICLEEMITTER] = "particle_emitter",
  [TYPE_TEXTURE] = "texture",
  [TYPE_FILE] = "file",
}

---@param typeId integer
---@return string
local function formatType(typeId)
  return TYPE_NAMES[typeId] or "unknown"
end

---@param timestamp number
---@return string
local function formatTimestamp(timestamp)
  return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

concommand.Add("rptools_state_list", function(ply)
  if IsValid(ply) and not ply:IsAdmin() then
    return
  end

  local schema = getSchema()
  local target = IsValid(ply) and ply or nil

  local function send(msg)
    if target then
      target:PrintMessage(HUD_PRINTCONSOLE, msg)
    else
      print(msg)
    end
  end

  send("RPTools State Schema")
  if #schema == 0 then
    send("(no state keys)")
    return
  end

  PrintTable(schema)

  for _, meta in ipairs(schema) do
    local scopeName = meta.scope == SCOPE.GLOBAL and "GLOBAL" or "PLAYER"
    send(
      string.format(
        "[%s] %s (type=%s, writes=%d, first=%s, last=%s)",
        scopeName,
        meta.key,
        formatType(meta.type),
        meta.writeCount,
        formatTimestamp(meta.firstSetAt),
        formatTimestamp(meta.lastSetAt)
      )
    )
  end
end)
